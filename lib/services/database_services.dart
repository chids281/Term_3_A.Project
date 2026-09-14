import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseServices {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User _requireUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in.');
    }

    return user;
  }

  // ================= CONVERSION HISTORY =================

  Future<void> saveConversion({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required double convertedAmount,
  }) async {
    final user = _requireUser();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('conversion_history')
        .add({
      'amount': amount,
      'fromCurrency': fromCurrency.toUpperCase(),
      'toCurrency': toCurrency.toUpperCase(),
      'convertedAmount': convertedAmount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getConversionHistory() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('conversion_history')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> deleteConversion(
    String conversionId,
  ) async {
    final user = _requireUser();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('conversion_history')
        .doc(conversionId)
        .delete();
  }

  Future<void> clearConversionHistory() async {
    final user = _requireUser();

    final history = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('conversion_history')
        .get();

    final batch = _firestore.batch();

    for (final document in history.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }

  // ================= RATE ALERTS =================

  Future<void> saveRateAlert({
    required String fromCurrency,
    required String toCurrency,
    required double targetRate,
    String condition = 'above',
  }) async {
    final user = _requireUser();

    final normalizedCondition =
        condition.toLowerCase().trim();

    if (normalizedCondition != 'above' &&
        normalizedCondition != 'below') {
      throw Exception(
        'The alert condition must be above or below.',
      );
    }

    if (fromCurrency.toUpperCase() ==
        toCurrency.toUpperCase()) {
      throw Exception(
        'Please select two different currencies.',
      );
    }

    if (targetRate <= 0) {
      throw Exception(
        'Please enter a valid target rate.',
      );
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rate_alerts')
        .add({
      'fromCurrency': fromCurrency.toUpperCase(),
      'toCurrency': toCurrency.toUpperCase(),
      'targetRate': targetRate,
      'condition': normalizedCondition,
      'isActive': true,
      'isTriggered': false,
      'lastCheckedRate': null,
      'lastCheckedAt': null,
      'triggeredRate': null,
      'triggeredAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getRateAlerts() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rate_alerts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>>
      getActiveRateAlerts() async {
    final user = _requireUser();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rate_alerts')
        .where('isActive', isEqualTo: true)
        .get();
  }

  Future<void> updateRateAlertStatus({
    required String alertId,
    required bool isActive,
  }) async {
    final user = _requireUser();

    final updateData = <String, dynamic>{
      'isActive': isActive,
    };

    // Reactivating an alert allows it to trigger again.
    if (isActive) {
      updateData.addAll({
        'isTriggered': false,
        'triggeredRate': null,
        'triggeredAt': null,
      });
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rate_alerts')
        .doc(alertId)
        .update(updateData);
  }

  Future<void> updateRateAlertCheck({
    required String alertId,
    required double currentRate,
  }) async {
    final user = _requireUser();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rate_alerts')
        .doc(alertId)
        .update({
      'lastCheckedRate': currentRate,
      'lastCheckedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> triggerRateAlert({
    required String alertId,
    required double currentRate,
  }) async {
    final user = _requireUser();

    final userReference = _firestore
        .collection('users')
        .doc(user.uid);

    final alertReference = userReference
        .collection('rate_alerts')
        .doc(alertId);

    final notificationReference = userReference
        .collection('notifications')
        .doc();

    return _firestore.runTransaction<bool>(
      (transaction) async {
        final alertSnapshot =
            await transaction.get(alertReference);

        if (!alertSnapshot.exists) {
          return false;
        }

        final alertData = alertSnapshot.data();

        if (alertData == null) {
          return false;
        }

        final isActive =
            alertData['isActive'] as bool? ?? false;

        final isTriggered =
            alertData['isTriggered'] as bool? ?? false;

        if (!isActive || isTriggered) {
          return false;
        }

        final fromCurrency =
            alertData['fromCurrency']?.toString() ?? '';

        final toCurrency =
            alertData['toCurrency']?.toString() ?? '';

        final targetRate =
            (alertData['targetRate'] as num?)
                    ?.toDouble() ??
                0;

        final condition =
            alertData['condition']?.toString() ??
                'above';

        transaction.update(alertReference, {
          'isActive': false,
          'isTriggered': true,
          'triggeredRate': currentRate,
          'triggeredAt': FieldValue.serverTimestamp(),
          'lastCheckedRate': currentRate,
          'lastCheckedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(notificationReference, {
          'type': 'rate_alert',
          'alertId': alertId,
          'title': 'Rate alert reached',
          'message':
              '1 $fromCurrency is now '
              '${_formatRate(currentRate)} $toCurrency. '
              'Your $condition target of '
              '${_formatRate(targetRate)} was reached.',
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
          'targetRate': targetRate,
          'currentRate': currentRate,
          'condition': condition,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      },
    );
  }

  Future<void> deleteRateAlert(
    String alertId,
  ) async {
    final user = _requireUser();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rate_alerts')
        .doc(alertId)
        .delete();
  }

  // ================= NOTIFICATIONS =================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getNotifications() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  Stream<int> getUnreadNotificationCount() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markNotificationAsRead(
    String notificationId,
  ) async {
    final user = _requireUser();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
    });
  }

  Future<void> markAllNotificationsAsRead() async {
    final user = _requireUser();

    final notifications = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (notifications.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final notification in notifications.docs) {
      batch.update(
        notification.reference,
        {'isRead': true},
      );
    }

    await batch.commit();
  }

  Future<void> deleteNotification(
    String notificationId,
  ) async {
    final user = _requireUser();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  static String _formatRate(double value) {
    if (value >= 100) {
      return value.toStringAsFixed(2);
    }

    if (value >= 1) {
      return value.toStringAsFixed(4);
    }

    return value.toStringAsFixed(6);
  }
}
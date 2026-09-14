import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _subjectController =
      TextEditingController();

  final TextEditingController _messageController =
      TextEditingController();

  final List<String> _issueCategories = [
    'Currency conversion',
    'Exchange rates',
    'Rate alerts',
    'Conversion history',
    'Account and login',
    'Other',
  ];

  String _selectedCategory = 'Currency conversion';
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitSupportRequest() async {
    final user = _auth.currentUser;
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (user == null) {
      _showMessage(
        'You must be logged in to submit a request.',
        isError: true,
      );
      return;
    }

    if (subject.isEmpty) {
      _showMessage(
        'Please enter a subject.',
        isError: true,
      );
      return;
    }

    if (message.length < 10) {
      _showMessage(
        'Please provide more information about the issue.',
        isError: true,
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('support_requests')
          .add({
        'category': _selectedCategory,
        'subject': subject,
        'message': message,
        'rating': _rating,
        'email': user.email,
        'status': 'submitted',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _subjectController.clear();
      _messageController.clear();

      setState(() {
        _selectedCategory = 'Currency conversion';
        _rating = 0;
      });

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            icon: const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF1FA97A),
              size: 50,
            ),
            title: const Text(
              'Request submitted',
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Your message has been saved successfully. '
              'Thank you for helping us improve CurrenSee.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFE5484D)
            : const Color(0xFF315CE2),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF071A40),
              Color(0xFF12347A),
              Color(0xFF315CE2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SupportHeader(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(24, 5, 24, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F9FD),
                    borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1450,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isLaptop =
                                constraints.maxWidth >= 950;

                            final informationPanel = Column(
                              children: const [
                                QuickHelpCard(),
                                SizedBox(height: 20),
                                FrequentlyAskedQuestions(),
                                SizedBox(height: 20),
                                AppInformationCard(),
                              ],
                            );

                            final supportForm = SupportFormCard(
                              subjectController: _subjectController,
                              messageController: _messageController,
                              categories: _issueCategories,
                              selectedCategory: _selectedCategory,
                              rating: _rating,
                              isSubmitting: _isSubmitting,
                              onCategoryChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              onRatingChanged: (value) {
                                setState(() {
                                  _rating = value;
                                });
                              },
                              onSubmit: _submitSupportRequest,
                            );

                            if (!isLaptop) {
                              return Column(
                                children: [
                                  informationPanel,
                                  const SizedBox(height: 20),
                                  supportForm,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: informationPanel,
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 6,
                                  child: supportForm,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportHeader extends StatelessWidget {
  const SupportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 22),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor:
                  Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help and support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Find answers, report an issue or share feedback.',
                  style: TextStyle(
                    color: Color(0xFFD7E4FF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFF8BE9FF),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Support centre',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickHelpCard extends StatelessWidget {
  const QuickHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102A56),
            Color(0xFF315CE2),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33315CE2),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Color(0xFF8BE9FF),
            child: Icon(
              Icons.question_answer_outlined,
              color: Color(0xFF071A40),
              size: 30,
            ),
          ),
          SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Check the common questions below or send '
                  'us a detailed support request.',
                  style: TextStyle(
                    color: Color(0xFFD7E4FF),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FrequentlyAskedQuestions extends StatelessWidget {
  const FrequentlyAskedQuestions({super.key});

  @override
  Widget build(BuildContext context) {
    return SupportCard(
      title: 'Frequently asked questions',
      icon: Icons.quiz_outlined,
      child: const Column(
        children: [
          FaqTile(
            question: 'Where do the exchange rates come from?',
            answer:
                'CurrenSee retrieves indicative exchange rates from '
                'ExchangeRate-API using its open-access endpoint.',
          ),
          Divider(color: Color(0xFFE5EAF3)),
          FaqTile(
            question: 'Why might a bank show a different rate?',
            answer:
                'Banks and payment providers may include fees, '
                'commissions and separate buying or selling rates.',
          ),
          Divider(color: Color(0xFFE5EAF3)),
          FaqTile(
            question: 'Where are my conversions saved?',
            answer:
                'Your conversion history is securely stored in '
                'Firebase under your authenticated user account.',
          ),
          Divider(color: Color(0xFFE5EAF3)),
          FaqTile(
            question: 'Can I pause a rate alert?',
            answer:
                'Yes. Open Rate Alerts and use the switch beside '
                'an alert to change it between active and paused.',
          ),
        ],
      ),
    );
  }
}

class FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const FaqTile({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: 16,
        ),
        iconColor: const Color(0xFF315CE2),
        collapsedIconColor: const Color(0xFF9AA7BC),
        title: Text(
          question,
          style: const TextStyle(
            color: Color(0xFF102A56),
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                color: Color(0xFF71809C),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppInformationCard extends StatelessWidget {
  const AppInformationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SupportCard(
      title: 'Application information',
      icon: Icons.info_outline_rounded,
      child: const Column(
        children: [
          InformationRow(
            label: 'Application',
            value: 'CurrenSee',
          ),
          Divider(color: Color(0xFFE5EAF3)),
          InformationRow(
            label: 'Platform',
            value: 'Flutter',
          ),
          Divider(color: Color(0xFFE5EAF3)),
          InformationRow(
            label: 'Authentication',
            value: 'Firebase Authentication',
          ),
          Divider(color: Color(0xFFE5EAF3)),
          InformationRow(
            label: 'Database',
            value: 'Cloud Firestore',
          ),
          Divider(color: Color(0xFFE5EAF3)),
          InformationRow(
            label: 'Exchange-rate provider',
            value: 'ExchangeRate-API',
          ),
        ],
      ),
    );
  }
}

class InformationRow extends StatelessWidget {
  final String label;
  final String value;

  const InformationRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF71809C),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF102A56),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SupportFormCard extends StatelessWidget {
  final TextEditingController subjectController;
  final TextEditingController messageController;
  final List<String> categories;
  final String selectedCategory;
  final int rating;
  final bool isSubmitting;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const SupportFormCard({
    super.key,
    required this.subjectController,
    required this.messageController,
    required this.categories,
    required this.selectedCategory,
    required this.rating,
    required this.isSubmitting,
    required this.onCategoryChanged,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SupportCard(
      title: 'Contact support',
      icon: Icons.mark_email_unread_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Issue category',
            style: TextStyle(
              color: Color(0xFF102A56),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            decoration: _inputDecoration(
              hint: 'Select a category',
              icon: Icons.category_outlined,
            ),
            items: categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 18),
          const Text(
            'Subject',
            style: TextStyle(
              color: Color(0xFF102A56),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: subjectController,
            decoration: _inputDecoration(
              hint: 'Briefly describe your issue',
              icon: Icons.subject_rounded,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Message',
            style: TextStyle(
              color: Color(0xFF102A56),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: messageController,
            minLines: 6,
            maxLines: 9,
            decoration: _inputDecoration(
              hint: 'Tell us what happened and how we can help...',
              icon: Icons.message_outlined,
              alignIconTop: true,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How would you rate your CurrenSee experience?',
            style: TextStyle(
              color: Color(0xFF102A56),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isSelected = starValue <= rating;

              return IconButton(
                tooltip: '$starValue stars',
                onPressed: () {
                  onRatingChanged(starValue);
                },
                icon: Icon(
                  isSelected
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: isSelected
                      ? const Color(0xFFFFB020)
                      : const Color(0xFFBBC4D2),
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF315CE2),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                isSubmitting
                    ? 'Submitting...'
                    : 'Submit support request',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool alignIconTop = false,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Padding(
        padding: EdgeInsets.only(
          bottom: alignIconTop ? 110 : 0,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF315CE2),
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF4F7FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE3E9F3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE3E9F3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF315CE2),
          width: 2,
        ),
      ),
    );
  }
}

class SupportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SupportCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE3E9F3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C102A56),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF315CE2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102A56),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
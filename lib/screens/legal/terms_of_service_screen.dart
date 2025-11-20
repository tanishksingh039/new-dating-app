import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Agreement to Terms',
              'By accessing or using ShooLuv ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, you may not use the App.',
            ),

            _buildSection(
              '1. Eligibility',
              '',
              children: [
                _buildBulletPoint('You must be at least 18 years old to use this App'),
                _buildBulletPoint('You must be a current student or affiliated with a participating university'),
                _buildBulletPoint('You must provide accurate and truthful information'),
                _buildBulletPoint('You must not have been previously banned from the App'),
                _buildBulletPoint('You must comply with all applicable laws and regulations'),
              ],
            ),

            _buildSection(
              '2. Account Registration',
              '',
              children: [
                _buildBulletPoint('You must create an account to use the App'),
                _buildBulletPoint('You are responsible for maintaining account security'),
                _buildBulletPoint('You must not share your account credentials'),
                _buildBulletPoint('You must notify us immediately of any unauthorized access'),
                _buildBulletPoint('One person may only maintain one account'),
              ],
            ),

            _buildSection(
              '3. User Conduct',
              'You agree NOT to:',
              children: [
                _buildBulletPoint('Harass, bully, or threaten other users'),
                _buildBulletPoint('Post offensive, hateful, or discriminatory content'),
                _buildBulletPoint('Share sexually explicit or inappropriate content'),
                _buildBulletPoint('Impersonate another person or entity'),
                _buildBulletPoint('Use fake photos or misleading information'),
                _buildBulletPoint('Spam or send unsolicited messages'),
                _buildBulletPoint('Solicit money or financial information'),
                _buildBulletPoint('Promote illegal activities or substances'),
                _buildBulletPoint('Violate intellectual property rights'),
                _buildBulletPoint('Attempt to hack or compromise the App'),
              ],
            ),

            _buildSection(
              '4. Content Guidelines',
              'All content you post must:',
              children: [
                _buildBulletPoint('Be appropriate and respectful'),
                _buildBulletPoint('Not contain nudity or sexual content'),
                _buildBulletPoint('Not promote violence or hate'),
                _buildBulletPoint('Not infringe on others\' rights'),
                _buildBulletPoint('Be your own original content or properly licensed'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Violation of content guidelines may result in immediate account suspension or termination.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            _buildSection(
              '5. Premium Features & Payments',
              '',
              children: [
                _buildSubSection(
                  'Subscription',
                  '• Premium subscriptions are billed monthly\n'
                  '• Subscriptions auto-renew unless cancelled\n'
                  '• Cancellation takes effect at end of billing period\n'
                  '• No refunds for partial months',
                ),
                _buildSubSection(
                  'In-App Purchases',
                  '• Swipe packs and Spotlight bookings are one-time purchases\n'
                  '• Purchases are non-refundable except as required by law\n'
                  '• Prices may change with notice\n'
                  '• All payments processed securely via Razorpay',
                ),
                _buildSubSection(
                  'Refund Policy',
                  '• Refunds only provided for technical issues\n'
                  '• Request refunds within 48 hours of purchase\n'
                  '• Contact support@shooluv.com for refund requests\n'
                  '• Refunds processed within 7-10 business days',
                ),
              ],
            ),

            _buildSection(
              '6. Intellectual Property',
              '',
              children: [
                _buildSubSection(
                  'Our Rights',
                  'ShooLuv and all related logos, designs, and content are owned by us. You may not copy, modify, or distribute our intellectual property without permission.',
                ),
                _buildSubSection(
                  'Your Content',
                  'You retain ownership of content you post. However, by posting content, you grant us a worldwide, non-exclusive, royalty-free license to use, display, and distribute your content within the App.',
                ),
              ],
            ),

            _buildSection(
              '7. Privacy & Data',
              'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your data. By using the App, you consent to our data practices as described in the Privacy Policy.',
            ),

            _buildSection(
              '8. Safety & Moderation',
              '',
              children: [
                _buildBulletPoint('We moderate content to maintain a safe environment'),
                _buildBulletPoint('We may remove content that violates our guidelines'),
                _buildBulletPoint('We investigate reports of misconduct'),
                _buildBulletPoint('We cooperate with law enforcement when necessary'),
                _buildBulletPoint('Users can block and report others'),
              ],
            ),

            _buildSection(
              '9. Account Termination',
              'We may suspend or terminate your account if:',
              children: [
                _buildBulletPoint('You violate these Terms of Service'),
                _buildBulletPoint('You violate our Community Guidelines'),
                _buildBulletPoint('You engage in illegal activities'),
                _buildBulletPoint('You harass or harm other users'),
                _buildBulletPoint('You create multiple accounts'),
                _buildBulletPoint('You are under 18 years old'),
                const SizedBox(height: 12),
                const Text(
                  'You may delete your account at any time from Settings. Upon deletion, your data will be permanently removed within 30 days.',
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                ),
              ],
            ),

            _buildSection(
              '10. Disclaimers',
              '',
              children: [
                _buildBulletPoint('The App is provided "as is" without warranties'),
                _buildBulletPoint('We do not guarantee matches or relationships'),
                _buildBulletPoint('We are not responsible for user conduct'),
                _buildBulletPoint('We do not verify user identities or backgrounds'),
                _buildBulletPoint('Use the App at your own risk'),
                _buildBulletPoint('Always meet in public places and practice safety'),
              ],
            ),

            _buildSection(
              '11. Limitation of Liability',
              'To the maximum extent permitted by law:',
              children: [
                _buildBulletPoint('We are not liable for indirect or consequential damages'),
                _buildBulletPoint('Our total liability is limited to the amount you paid us'),
                _buildBulletPoint('We are not responsible for user interactions or relationships'),
                _buildBulletPoint('We are not liable for third-party services (e.g., Razorpay)'),
              ],
            ),

            _buildSection(
              '12. Indemnification',
              'You agree to indemnify and hold us harmless from any claims, damages, or expenses arising from:',
              children: [
                _buildBulletPoint('Your use of the App'),
                _buildBulletPoint('Your violation of these Terms'),
                _buildBulletPoint('Your violation of others\' rights'),
                _buildBulletPoint('Content you post on the App'),
              ],
            ),

            _buildSection(
              '13. Geographic Restrictions',
              'ShooLuv is currently available only at participating universities. We reserve the right to restrict access based on location. Future expansion to other universities will be announced.',
            ),

            _buildSection(
              '14. Changes to Terms',
              'We may update these Terms from time to time. We will notify you of significant changes via:',
              children: [
                _buildBulletPoint('In-app notification'),
                _buildBulletPoint('Email notification'),
                _buildBulletPoint('Updated "Last updated" date'),
                const SizedBox(height: 8),
                const Text(
                  'Continued use of the App after changes constitutes acceptance of the new Terms.',
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                ),
              ],
            ),

            _buildSection(
              '15. Dispute Resolution',
              '',
              children: [
                _buildSubSection(
                  'Governing Law',
                  'These Terms are governed by the laws of India. Any disputes will be resolved in the courts of Himachal Pradesh, India.',
                ),
                _buildSubSection(
                  'Arbitration',
                  'For disputes under ₹1,00,000, we encourage informal resolution. Contact us at legal@shooluv.com to resolve disputes.',
                ),
              ],
            ),

            _buildSection(
              '16. Severability',
              'If any provision of these Terms is found to be unenforceable, the remaining provisions will remain in full effect.',
            ),

            _buildSection(
              '17. Contact Information',
              'For questions about these Terms:',
              children: [
                const SizedBox(height: 8),
                _buildContactInfo('Email', 'legal@shooluv.com'),
                _buildContactInfo('Support', 'support@shooluv.com'),
                _buildContactInfo('Address', 'Shoolini University, Solan, Himachal Pradesh, India'),
              ],
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Important Notice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By using ShooLuv, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service and our Privacy Policy.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {List<Widget>? children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 12),
        if (content.isNotEmpty)
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        if (children != null) ...children,
      ],
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

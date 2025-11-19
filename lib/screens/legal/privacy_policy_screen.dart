import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
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
              'Introduction',
              'shooLuv ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our dating application.',
            ),

            _buildSection(
              '1. Information We Collect',
              '',
              children: [
                _buildSubSection(
                  'Personal Information',
                  '• Name and date of birth\n'
                  '• Email address and phone number\n'
                  '• Gender and sexual orientation\n'
                  '• Profile photos and bio\n'
                  '• University/college information\n'
                  '• Interests and preferences',
                ),
                _buildSubSection(
                  'Location Data',
                  '• Approximate location (for matching purposes)\n'
                  '• University geolocation\n'
                  '• We do NOT track your precise real-time location',
                ),
                _buildSubSection(
                  'Usage Information',
                  '• App interactions (swipes, matches, messages)\n'
                  '• Device information (model, OS version)\n'
                  '• Log data and analytics\n'
                  '• Payment transaction data (via Razorpay)',
                ),
                _buildSubSection(
                  'User-Generated Content',
                  '• Chat messages\n'
                  '• Photos shared in conversations\n'
                  '• Voice messages (if applicable)\n'
                  '• Profile information and updates',
                ),
              ],
            ),

            _buildSection(
              '2. How We Use Your Information',
              '',
              children: [
                _buildBulletPoint('Provide and maintain our dating service'),
                _buildBulletPoint('Match you with compatible users'),
                _buildBulletPoint('Process payments and transactions'),
                _buildBulletPoint('Send notifications about matches and messages'),
                _buildBulletPoint('Improve app features and user experience'),
                _buildBulletPoint('Detect and prevent fraud, abuse, and violations'),
                _buildBulletPoint('Comply with legal obligations'),
                _buildBulletPoint('Respond to support requests'),
              ],
            ),

            _buildSection(
              '3. Information Sharing',
              'We do NOT sell your personal information. We may share your information only in these cases:',
              children: [
                _buildSubSection(
                  'With Other Users',
                  '• Your profile information is visible to other users\n'
                  '• Messages are shared with matched users\n'
                  '• You control what information appears on your profile',
                ),
                _buildSubSection(
                  'Service Providers',
                  '• Firebase (Google) - Database and authentication\n'
                  '• Razorpay - Payment processing\n'
                  '• Cloud storage providers - Photo storage\n'
                  '• Analytics providers - App improvement',
                ),
                _buildSubSection(
                  'Legal Requirements',
                  '• To comply with laws and regulations\n'
                  '• To respond to legal requests\n'
                  '• To protect rights and safety\n'
                  '• To prevent fraud and abuse',
                ),
              ],
            ),

            _buildSection(
              '4. Data Retention',
              '',
              children: [
                _buildBulletPoint('Active accounts: Data retained while account is active'),
                _buildBulletPoint('Deleted accounts: Data deleted within 30 days'),
                _buildBulletPoint('Legal requirements: Some data may be retained longer if required by law'),
                _buildBulletPoint('Backups: Deleted data removed from backups within 90 days'),
              ],
            ),

            _buildSection(
              '5. Your Rights',
              'You have the right to:',
              children: [
                _buildBulletPoint('Access your personal data'),
                _buildBulletPoint('Correct inaccurate information'),
                _buildBulletPoint('Delete your account and data'),
                _buildBulletPoint('Export your data (data portability)'),
                _buildBulletPoint('Opt-out of marketing communications'),
                _buildBulletPoint('Withdraw consent at any time'),
              ],
            ),

            _buildSection(
              '6. Data Security',
              'We implement appropriate security measures:',
              children: [
                _buildBulletPoint('Encryption in transit (HTTPS/SSL)'),
                _buildBulletPoint('Secure cloud storage (Firebase)'),
                _buildBulletPoint('Access controls and authentication'),
                _buildBulletPoint('Regular security audits'),
                _buildBulletPoint('Employee training on data protection'),
              ],
            ),

            _buildSection(
              '7. Age Requirement',
              'You must be 18 years or older to use shooLuv. We do not knowingly collect information from users under 18. If we discover a user is under 18, we will immediately delete their account and data.',
            ),

            _buildSection(
              '8. Location-Based Services',
              'We use your location to:',
              children: [
                _buildBulletPoint('Show you matches from your university'),
                _buildBulletPoint('Calculate distance to other users'),
                _buildBulletPoint('Verify university affiliation'),
                const SizedBox(height: 8),
                const Text(
                  'You can disable location services in your device settings, but this may limit app functionality.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),

            _buildSection(
              '9. Cookies and Tracking',
              'We use cookies and similar technologies for:',
              children: [
                _buildBulletPoint('Authentication and security'),
                _buildBulletPoint('Preferences and settings'),
                _buildBulletPoint('Analytics and performance'),
                _buildBulletPoint('You can manage cookies in your device settings'),
              ],
            ),

            _buildSection(
              '10. Third-Party Services',
              'Our app integrates with:',
              children: [
                _buildSubSection(
                  'Firebase (Google)',
                  'Database, authentication, storage, and analytics\n'
                  'Privacy Policy: https://firebase.google.com/support/privacy',
                ),
                _buildSubSection(
                  'Razorpay',
                  'Payment processing\n'
                  'Privacy Policy: https://razorpay.com/privacy',
                ),
              ],
            ),

            _buildSection(
              '11. International Data Transfers',
              'Your data may be transferred to and stored in servers located outside your country. We ensure appropriate safeguards are in place to protect your data in accordance with this Privacy Policy.',
            ),

            _buildSection(
              '12. Changes to Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of significant changes via:',
              children: [
                _buildBulletPoint('In-app notification'),
                _buildBulletPoint('Email notification'),
                _buildBulletPoint('Updated "Last updated" date'),
              ],
            ),

            _buildSection(
              '13. Contact Us',
              'For privacy-related questions or to exercise your rights:',
              children: [
                const SizedBox(height: 8),
                _buildContactInfo('Email', 'privacy@shooluv.com'),
                _buildContactInfo('Support', 'support@shooluv.com'),
                _buildContactInfo('Address', 'Shoolini University, Solan, Himachal Pradesh, India'),
              ],
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Your Privacy Matters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We are committed to protecting your privacy and being transparent about our data practices. If you have any concerns, please contact us.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
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

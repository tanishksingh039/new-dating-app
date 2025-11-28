import 'package:flutter/material.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Guidelines'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community Guidelines',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Building a safe and respectful community',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Welcome to ShooLuv!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Our community is built on respect, kindness, and authenticity. These guidelines help create a safe space for everyone.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            _buildSection(
              '✅ Do\'s - What We Encourage',
              '',
              children: [
                _buildDoItem('Be Yourself', 'Use real photos and honest information'),
                _buildDoItem('Be Respectful', 'Treat others with kindness and courtesy'),
                _buildDoItem('Be Safe', 'Meet in public places, tell friends your plans'),
                _buildDoItem('Be Authentic', 'Share genuine interests and intentions'),
                _buildDoItem('Be Positive', 'Spread good vibes and encouragement'),
                _buildDoItem('Report Issues', 'Help us keep the community safe'),
              ],
            ),

            _buildSection(
              '❌ Don\'ts - Prohibited Behavior',
              '',
              children: [
                _buildDontItem('Harassment', 'No bullying, threats, or intimidation'),
                _buildDontItem('Hate Speech', 'No discrimination based on race, religion, gender, etc.'),
                _buildDontItem('Nudity/Sexual Content', 'Keep photos and messages appropriate'),
                _buildDontItem('Fake Profiles', 'No catfishing or impersonation'),
                _buildDontItem('Spam', 'No unsolicited messages or promotions'),
                _buildDontItem('Solicitation', 'No asking for money or financial info'),
                _buildDontItem('Illegal Activity', 'No drugs, violence, or illegal content'),
                _buildDontItem('Minors', 'Must be 18+ to use the app'),
              ],
            ),

            _buildSection(
              '📸 Photo Guidelines',
              'Your photos should:',
              children: [
                _buildBulletPoint('Clearly show your face'),
                _buildBulletPoint('Be recent (within last year)'),
                _buildBulletPoint('Be appropriate (no nudity or suggestive poses)'),
                _buildBulletPoint('Be of you (not celebrities or random people)'),
                _buildBulletPoint('Not include children'),
                _buildBulletPoint('Not contain offensive symbols or gestures'),
              ],
            ),

            _buildSection(
              '💬 Messaging Guidelines',
              'When chatting:',
              children: [
                _buildBulletPoint('Start with a friendly greeting'),
                _buildBulletPoint('Respect boundaries if someone isn\'t interested'),
                _buildBulletPoint('Don\'t send unsolicited explicit content'),
                _buildBulletPoint('Don\'t share personal information too quickly'),
                _buildBulletPoint('Don\'t pressure anyone for photos or meetings'),
                _buildBulletPoint('Report inappropriate messages immediately'),
              ],
            ),

            _buildSection(
              '🛡️ Safety Tips',
              'Stay safe while dating:',
              children: [
                _buildSafetyTip('Meet in Public', 'First meetings should be in busy, public places'),
                _buildSafetyTip('Tell Someone', 'Let friends/family know where you\'re going'),
                _buildSafetyTip('Trust Your Gut', 'If something feels off, it probably is'),
                _buildSafetyTip('Stay Sober', 'Keep your wits about you on first dates'),
                _buildSafetyTip('Don\'t Share Too Much', 'Protect your personal information'),
                _buildSafetyTip('Use App Messaging', 'Keep conversations in-app initially'),
              ],
            ),

            _buildSection(
              '⚠️ Consequences of Violations',
              'Violating these guidelines may result in:',
              children: [
                _buildConsequence('1st Offense', 'Warning and content removal'),
                _buildConsequence('2nd Offense', 'Temporary account suspension (7 days)'),
                _buildConsequence('3rd Offense', 'Permanent account ban'),
                _buildConsequence('Severe Violations', 'Immediate permanent ban'),
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
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Severe violations (harassment, illegal content, minors) result in immediate ban and may be reported to authorities.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            _buildSection(
              '🚨 How to Report',
              'If you see something concerning:',
              children: [
                _buildBulletPoint('Tap the menu (⋮) on any profile or chat'),
                _buildBulletPoint('Select "Report User"'),
                _buildBulletPoint('Choose the reason for reporting'),
                _buildBulletPoint('Provide details if needed'),
                _buildBulletPoint('Our team will review within 24 hours'),
                const SizedBox(height: 12),
                const Text(
                  'All reports are confidential. The reported user will not know who reported them.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            _buildSection(
              '🔒 Privacy & Data',
              'We respect your privacy:',
              children: [
                _buildBulletPoint('Your data is encrypted and secure'),
                _buildBulletPoint('We never sell your information'),
                _buildBulletPoint('You control what appears on your profile'),
                _buildBulletPoint('You can delete your account anytime'),
                _buildBulletPoint('Read our Privacy Policy for details'),
              ],
            ),

            _buildSection(
              '💡 Tips for Success',
              'Make the most of ShooLuv:',
              children: [
                _buildBulletPoint('Complete your profile with interesting details'),
                _buildBulletPoint('Use high-quality, recent photos'),
                _buildBulletPoint('Be genuine in your conversations'),
                _buildBulletPoint('Don\'t take rejection personally'),
                _buildBulletPoint('Have fun and be yourself!'),
              ],
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Thank You!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By following these guidelines, you help create a positive experience for everyone. Happy matching!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'Questions or concerns?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'shooluvbusiness07@gmail.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFF6B9D),
                      fontWeight: FontWeight.w600,
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

  Widget _buildDoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 16, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDontItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, size: 16, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield, size: 16, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsequence(String offense, String consequence) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              offense,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
          Expanded(
            child: Text(
              consequence,
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
}

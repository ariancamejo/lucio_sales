import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: October 30, 2025',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              title: '1. Introduction',
              content:
                  'Welcome to Lucio Sales. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains what information we collect, how we use it, and what rights you have in relation to it.',
            ),

            _buildSection(
              context,
              title: '2. Information We Collect',
              content:
                  'We collect information that you provide directly to us when using our inventory management system:\n\n'
                  '• Account Information: Email address, name, and authentication credentials\n'
                  '• Business Data: Product information, inventory records, sales data, and stock entries\n'
                  '• Usage Data: Information about how you interact with our application\n'
                  '• Device Information: Device type, operating system, and browser information',
            ),

            _buildSection(
              context,
              title: '3. How We Use Your Information',
              content:
                  'We use the information we collect to:\n\n'
                  '• Provide, maintain, and improve our services\n'
                  '• Process your transactions and manage your inventory\n'
                  '• Send you technical notices and support messages\n'
                  '• Synchronize your data across devices\n'
                  '• Generate reports and analytics for your business\n'
                  '• Detect and prevent fraud or security issues',
            ),

            _buildSection(
              context,
              title: '4. Data Storage and Security',
              content:
                  'Your data is stored both locally on your device and in our secure cloud database powered by Supabase. We implement appropriate technical and organizational measures to protect your personal information:\n\n'
                  '• End-to-end encryption for data transmission\n'
                  '• Secure authentication using industry-standard protocols\n'
                  '• Regular security audits and updates\n'
                  '• Local data synchronization with offline-first architecture',
            ),

            _buildSection(
              context,
              title: '5. Data Sharing',
              content:
                  'We do not sell, trade, or rent your personal information to third parties. We only share your information in the following circumstances:\n\n'
                  '• With your explicit consent\n'
                  '• To comply with legal obligations\n'
                  '• To protect our rights and prevent fraud\n'
                  '• With service providers who assist in our operations (e.g., cloud hosting)',
            ),

            _buildSection(
              context,
              title: '6. Your Rights',
              content:
                  'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Correct inaccurate data\n'
                  '• Request deletion of your data\n'
                  '• Export your data in a portable format\n'
                  '• Withdraw consent at any time\n'
                  '• Object to processing of your data',
            ),

            _buildSection(
              context,
              title: '7. Data Retention',
              content:
                  'We retain your personal information for as long as necessary to provide our services and comply with legal obligations. When you delete your account, we will delete or anonymize your personal information within 30 days, except where we are required to retain it by law.',
            ),

            _buildSection(
              context,
              title: '8. Children\'s Privacy',
              content:
                  'Our service is not intended for users under the age of 18. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
            ),

            _buildSection(
              context,
              title: '9. Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            ),

            _buildSection(
              context,
              title: '10. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy or our data practices, please contact us at:\n\n'
                  'Email: support@luciosales.com\n'
                  'Address: [Your Business Address]',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

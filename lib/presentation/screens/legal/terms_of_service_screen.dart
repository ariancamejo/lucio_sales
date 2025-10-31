import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using Lucio Sales ("the Service"), you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to these Terms of Service, please do not use the Service.',
            ),

            _buildSection(
              context,
              title: '2. Description of Service',
              content:
                  'Lucio Sales provides an inventory management system that allows you to:\n\n'
                  '• Track products and inventory levels\n'
                  '• Record stock entries and outputs\n'
                  '• Generate sales reports and analytics\n'
                  '• Manage measurement units and product categories\n'
                  '• Synchronize data across multiple devices\n'
                  '• Maintain audit history of all operations',
            ),

            _buildSection(
              context,
              title: '3. User Accounts',
              content:
                  'To use the Service, you must:\n\n'
                  '• Create an account with accurate and complete information\n'
                  '• Maintain the security of your account credentials\n'
                  '• Be at least 18 years of age\n'
                  '• Not share your account with others\n'
                  '• Notify us immediately of any unauthorized access\n\n'
                  'You are responsible for all activities that occur under your account.',
            ),

            _buildSection(
              context,
              title: '4. Acceptable Use',
              content:
                  'You agree to use the Service only for lawful purposes. You must not:\n\n'
                  '• Violate any applicable laws or regulations\n'
                  '• Infringe upon the rights of others\n'
                  '• Attempt to gain unauthorized access to the Service\n'
                  '• Interfere with the proper functioning of the Service\n'
                  '• Use the Service to transmit malicious code or viruses\n'
                  '• Use automated systems to access the Service without permission\n'
                  '• Reverse engineer or attempt to extract source code',
            ),

            _buildSection(
              context,
              title: '5. Data and Content',
              content:
                  'You retain all rights to the data you input into the Service. By using the Service, you grant us a limited license to:\n\n'
                  '• Store and process your data to provide the Service\n'
                  '• Create backups of your data\n'
                  '• Generate analytics and insights from your data\n\n'
                  'You are responsible for:\n\n'
                  '• The accuracy of your data\n'
                  '• Maintaining appropriate backups\n'
                  '• Compliance with data protection regulations',
            ),

            _buildSection(
              context,
              title: '6. Service Availability',
              content:
                  'We strive to provide reliable and continuous service, but we do not guarantee:\n\n'
                  '• Uninterrupted access to the Service\n'
                  '• Error-free operation\n'
                  '• That the Service will meet your specific requirements\n\n'
                  'We may modify, suspend, or discontinue any part of the Service at any time with reasonable notice.',
            ),

            _buildSection(
              context,
              title: '7. Intellectual Property',
              content:
                  'The Service, including its design, features, and functionality, is owned by Lucio Sales and is protected by copyright, trademark, and other intellectual property laws. You may not:\n\n'
                  '• Copy, modify, or distribute the Service\n'
                  '• Remove any copyright or proprietary notices\n'
                  '• Create derivative works based on the Service',
            ),

            _buildSection(
              context,
              title: '8. Payment and Subscriptions',
              content:
                  'If applicable:\n\n'
                  '• Subscription fees are billed in advance\n'
                  '• All fees are non-refundable unless required by law\n'
                  '• We may change our fees with 30 days notice\n'
                  '• You can cancel your subscription at any time\n'
                  '• Failure to pay may result in service suspension',
            ),

            _buildSection(
              context,
              title: '9. Limitation of Liability',
              content:
                  'To the maximum extent permitted by law, Lucio Sales shall not be liable for:\n\n'
                  '• Any indirect, incidental, or consequential damages\n'
                  '• Loss of data, profits, or business opportunities\n'
                  '• Damages resulting from unauthorized access to your account\n'
                  '• Service interruptions or errors\n\n'
                  'Our total liability shall not exceed the amount you paid for the Service in the past 12 months.',
            ),

            _buildSection(
              context,
              title: '10. Indemnification',
              content:
                  'You agree to indemnify and hold harmless Lucio Sales from any claims, damages, losses, or expenses arising from:\n\n'
                  '• Your use of the Service\n'
                  '• Your violation of these Terms\n'
                  '• Your violation of any rights of another party\n'
                  '• Your data or content',
            ),

            _buildSection(
              context,
              title: '11. Termination',
              content:
                  'We may terminate or suspend your account and access to the Service:\n\n'
                  '• For violation of these Terms\n'
                  '• For fraudulent or illegal activity\n'
                  '• Upon your request\n'
                  '• For extended periods of inactivity\n\n'
                  'Upon termination, your right to use the Service will immediately cease, and we may delete your data after 30 days.',
            ),

            _buildSection(
              context,
              title: '12. Changes to Terms',
              content:
                  'We reserve the right to modify these Terms at any time. We will notify you of material changes by:\n\n'
                  '• Posting the updated Terms on the Service\n'
                  '• Sending you an email notification\n'
                  '• Displaying a notice in the application\n\n'
                  'Your continued use of the Service after changes constitutes acceptance of the new Terms.',
            ),

            _buildSection(
              context,
              title: '13. Governing Law',
              content:
                  'These Terms shall be governed by and construed in accordance with the laws of [Your Jurisdiction], without regard to its conflict of law provisions. Any disputes shall be resolved in the courts of [Your Jurisdiction].',
            ),

            _buildSection(
              context,
              title: '14. Contact Information',
              content:
                  'If you have any questions about these Terms of Service, please contact us at:\n\n'
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

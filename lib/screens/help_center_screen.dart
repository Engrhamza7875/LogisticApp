import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How can we help?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('Search our FAQ or contact our logistics team', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _faqTile('How do I track my shipment?', 'Use the search bar on the home screen and enter your tracking number (e.g., SAB-2024-001).'),
            _faqTile('What is the shipping rate per kg?', 'Standard shipping starts at 30.0 SAR per kg, depending on the destination and cargo type.'),
            _faqTile('How can I reset my access PIN?', 'Go to Profile > Security & PIN to reset your access code via email OTP.'),
            _faqTile('Where are your offices located?', 'We have hubs in Riyadh, Jeddah, Dammam, and Medina. Check our locations for details.'),
            
            const SizedBox(height: 32),
            const Text('CONTACT SUPPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _contactCard(Icons.email_outlined, 'Email Support', 'support@sabcargo.dev', Colors.blue),
            _contactCard(Icons.phone_outlined, 'Call Us', '+966 800 123 4567', Colors.green),
            _contactCard(Icons.chat_bubble_outline_rounded, 'Live Chat', 'Chat with our AI bot', AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(String q, String a) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Text(q, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(a, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(IconData icon, String title, String val, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(val, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}

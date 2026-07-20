import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/romantic_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(KhmerText.aboutTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppColors.heroGradient),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 46),
            ),
            const SizedBox(height: 20),
            Text(
              KhmerText.appName,
              style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 22, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              '${KhmerText.aboutVersion} 1.0.0',
              style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            RomanticCard(
              child: Text(
                KhmerText.aboutDescription,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 14, color: AppColors.textDark, height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.favorite, color: AppColors.primaryLight),
          ],
        ),
      ),
    );
  }
}

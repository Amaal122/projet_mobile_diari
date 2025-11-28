// Diari - Prototype fidèle au design fourni (Onboarding, Login, Home)
import 'package:flutter/material.dart';
import 'onboarding_page.dart';

void main() => runApp(const DiariPrototype());

class DiariPrototype extends StatelessWidget {
  const DiariPrototype({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diari Prototype',
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: OnboardingPage(),
      ),
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF7EFE6),
        fontFamily: 'Roboto',
      ),
    );
  }
}

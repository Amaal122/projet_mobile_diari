import 'package:flutter/material.dart';
import 'login_page.dart';

// ---------------- Onboarding ----------------
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () {},
                ),
              ),
              const Expanded(
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: Color(0xFFF0D88B),
                            child: Icon(
                              Icons.home_outlined,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 18),
                          Text(
                            'ذوق طعم الدار من جديد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'عيش الدفء، والراحة متاع الأكل الحقيقي المصنوع في الدار',
                            textAlign: TextAlign.center,
                          ),
                          Spacer(),
                          SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFCB675B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text('ابدأ', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'api_service.dart';
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFCB675B),
        title: const Text('إنشاء حساب'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      'DIARI',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أنشئ حسابك للتمتع بخدمات دْياري',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 20),

                    _buildInput(
                      controller: _name,
                      hint: 'الإسم الكامل',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),

                    _buildInput(
                      controller: _email,
                      hint: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),

                    _buildInput(
                      controller: _pass,
                      hint: 'كلمة المرور',
                      obscure: true,
                      icon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 12),

                    _buildInput(
                      controller: _confirm,
                      hint: 'تأكيد كلمة المرور',
                      obscure: true,
                      icon: Icons.lock_reset,
                    ),
                    const SizedBox(height: 18),

                    // BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCB675B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'إنشاء الحساب',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'عندك حساب؟ تسجيل الدخول',
                        style: TextStyle(
                          color: Color(0xFFCB675B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: Icon(icon),
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

 void _register() async {
    // 1. Basic Validation (Keep existing checks)
    if (_name.text.isEmpty ||
        _email.text.isEmpty ||
        _pass.text.isEmpty ||
        _confirm.text.isEmpty) {
      _showMessage('الرجاء تعمير جميع الخانات');
      return;
    }

    if (_pass.text != _confirm.text) {
      _showMessage('كلمتا المرور غير متطابقتين');
      return;
    }

    // 2. Show "Loading" message
    _showMessage('جاري الاتصال بالخادم...');

    // 3. Call the Python Backend
    // We pass: Name, Email, Password
    var result = await ApiService.signup(
      _name.text, 
      _email.text, 
      _pass.text
    );

    // 4. Check the result
    if (result.containsKey('success')) {
      // SUCCESS: The server said "True"
      _showMessage('تم إنشاء الحساب بنجاح ✔');
      
      // Optional: Wait 1 second then close the page
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      // ERROR: The server returned an error (like "Email already exists")
      // We show the specific error message from Python
      _showMessage('خطأ: ${result['error']}');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: const Color(0xFFCB675B),
      ),
    );
  }
}

// End of file

import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/auth_service.dart';

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
  bool _isLoading = false;
  String? _emailError;
  String? _passError;
  String? _confirmError;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

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
        backgroundColor: AppColors.primary,
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
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 12),

                    _buildInput(
                      controller: _pass,
                      hint: 'كلمة المرور',
                      obscure: true,
                      icon: Icons.lock_outline,
                      errorText: _passError,
                    ),
                    const SizedBox(height: 12),

                    _buildInput(
                      controller: _confirm,
                      hint: 'تأكيد كلمة المرور',
                      obscure: true,
                      icon: Icons.lock_reset,
                      errorText: _confirmError,
                    ),
                    const SizedBox(height: 18),

                    // BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
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
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: Icon(icon),
        hintText: hint,
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _register() async {
    setState(() {
      _emailError = null;
      _passError = null;
      _confirmError = null;
    });

    if (_name.text.isEmpty ||
        _email.text.isEmpty ||
        _pass.text.isEmpty ||
        _confirm.text.isEmpty) {
      _showMessage('الرجاء تعمير جميع الخانات');
      return;
    }

    if (!_isValidEmail(_email.text)) {
      setState(() {
        _emailError = 'البريد الإلكتروني غير صحيح';
      });
      _showMessage('البريد الإلكتروني غير صحيح');
      return;
    }

    if (_pass.text.length < 6) {
      setState(() {
        _passError = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      });
      _showMessage('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    if (_pass.text != _confirm.text) {
      setState(() {
        _confirmError = 'كلمتا المرور غير متطابقتين';
      });
      _showMessage('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Real Firebase Authentication
    final result = await AuthService.signUp(
      email: _email.text.trim(),
      password: _pass.text,
      displayName: _name.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      _showMessage('تم إنشاء الحساب بنجاح ✔');
      // Go back to login page
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      _showMessage(result.error ?? 'فشل إنشاء الحساب');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

// End of file

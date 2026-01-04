import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/chef_service.dart';
import '../state/app_state.dart';

const Color _primary = AppColors.primary;

class ChefSignupPage extends StatefulWidget {
  const ChefSignupPage({super.key});

  @override
  State<ChefSignupPage> createState() => _ChefSignupPageState();
}

class _ChefSignupPageState extends State<ChefSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  final List<String> _selectedSpecialties = [];

  final List<Map<String, String>> _specialties = [
    {'id': 'tunisian', 'name': 'تونسي'},
    {'id': 'seafood', 'name': 'بحري'},
    {'id': 'grilled', 'name': 'مشوي'},
    {'id': 'pasta', 'name': 'مقرونة'},
    {'id': 'couscous', 'name': 'كسكسي'},
    {'id': 'traditional', 'name': 'تقليدي'},
    {'id': 'desserts', 'name': 'حلويات'},
    {'id': 'healthy', 'name': 'صحي'},
  ];

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  void _prefillUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _registerAsChef() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('يجب تسجيل الدخول أولاً');
        return;
      }

      final response = await ChefService.registerAsChef(
        userId: user.uid,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
        specialties: _selectedSpecialties,
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (response.success && mounted) {
        // Update app state
        AppState().setUserRole('chef');
        
        // Save chef status to SharedPreferences for persistence
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isChef', true);
          await prefs.setString('userId', user.uid);
          print('Chef status saved to SharedPreferences');
        } catch (e) {
          debugPrint('Error saving chef status: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التسجيل كطباخ بنجاح!'),
            backgroundColor: _primary,
          ),
        );
        
        // Navigate to chef dashboard
        Navigator.pushReplacementNamed(context, '/chef');
      } else {
        _showError(response.error ?? 'فشل التسجيل');
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: _primary,
          title: const Text('التسجيل كطباخ'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_menu, size: 60, color: _primary),
                      const SizedBox(height: 12),
                      const Text(
                        'انضم إلى فريق الطباخين',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'شارك وصفاتك المنزلية مع العملاء',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المطبخ / الطباخ *',
                    hintText: 'مثال: مطبخ أم محمد',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Bio Field
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'نبذة عنك',
                    hintText: 'اكتب نبذة قصيرة عن خبرتك في الطبخ...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.info_outline),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف *',
                    hintText: '12345678',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال رقم الهاتف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Location Field
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'المنطقة *',
                    hintText: 'مثال: تونس العاصمة، المرسى',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال المنطقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Address Field
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'العنوان التفصيلي',
                    hintText: 'الشارع، رقم المنزل...',
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Specialties
                const Text(
                  'تخصصاتك في الطبخ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _specialties.map((specialty) {
                    final isSelected = _selectedSpecialties.contains(specialty['id']);
                    return FilterChip(
                      label: Text(specialty['name']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSpecialties.add(specialty['id']!);
                          } else {
                            _selectedSpecialties.remove(specialty['id']);
                          }
                        });
                      },
                      selectedColor: _primary.withOpacity(0.2),
                      checkmarkColor: _primary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerAsChef,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ابدأ الآن',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Terms note
                Text(
                  'بالتسجيل، أنت توافق على شروط الاستخدام وسياسة الخصوصية',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

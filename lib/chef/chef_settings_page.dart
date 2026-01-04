import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/chef_service.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';

const Color _primary = AppColors.primary;

class ChefSettingsPage extends StatefulWidget {
  const ChefSettingsPage({super.key});

  @override
  State<ChefSettingsPage> createState() => _ChefSettingsPageState();
}

class _ChefSettingsPageState extends State<ChefSettingsPage> {
  bool _isLoading = false;
  bool _isAvailable = true;
  bool _acceptNewOrders = true;
  bool _orderNotifications = true;
  bool _reviewNotifications = true;
  bool _promotionalNotifications = false;
  String _defaultPrepTime = '30';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load from API first
      final response = await ChefService.getProfile(user.uid);
      if (response.success && mounted) {
        setState(() {
          _isAvailable = response.data?['isActive'] ?? response.data?['isAvailable'] ?? true;
        });
      }

      // Load preferences from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _acceptNewOrders = prefs.getBool('chef_acceptNewOrders') ?? true;
        _orderNotifications = prefs.getBool('chef_orderNotifications') ?? true;
        _reviewNotifications = prefs.getBool('chef_reviewNotifications') ?? true;
        _promotionalNotifications = prefs.getBool('chef_promotionalNotifications') ?? false;
        _defaultPrepTime = prefs.getString('chef_defaultPrepTime') ?? '30';
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Update availability via API
      final availResponse = await ChefService.toggleAvailability(
        userId: user.uid,
        isActive: _isAvailable,
      );
      
      if (!availResponse.success) {
        throw Exception('Failed to update availability');
      }

      // Save settings to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chef_acceptNewOrders', _acceptNewOrders);
      await prefs.setBool('chef_orderNotifications', _orderNotifications);
      await prefs.setBool('chef_reviewNotifications', _reviewNotifications);
      await prefs.setBool('chef_promotionalNotifications', _promotionalNotifications);
      await prefs.setString('chef_defaultPrepTime', _defaultPrepTime);
      await prefs.setBool('chef_isAvailable', _isAvailable); // Save availability too

      // Update notification subscriptions
      try {
        if (_orderNotifications) {
          await NotificationService.subscribeToTopic('chef_${user.uid}_orders');
        } else {
          await NotificationService.unsubscribeFromTopic('chef_${user.uid}_orders');
        }
      } catch (e) {
        debugPrint('Notification subscription error (non-fatal): $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج', textDirection: TextDirection.rtl),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟', textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();
    AppState().clearUser();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: _primary,
          title: const Text('الإعدادات'),
          centerTitle: true,
          actions: [
            if (!_isLoading)
              TextButton(
                onPressed: _saveSettings,
                child: const Text('حفظ', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Availability Section
                    _buildSectionTitle('التوفر'),
                    _buildSettingsCard([
                      _buildSwitchTile(
                        icon: Icons.store,
                        title: 'متاح للطلبات',
                        subtitle: 'إظهار ملفك للعملاء',
                        value: _isAvailable,
                        onChanged: (v) => setState(() => _isAvailable = v),
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        icon: Icons.receipt_long,
                        title: 'قبول طلبات جديدة',
                        subtitle: 'السماح للعملاء بإرسال طلبات جديدة',
                        value: _acceptNewOrders,
                        onChanged: (v) => setState(() => _acceptNewOrders = v),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Notifications Section
                    _buildSectionTitle('الإشعارات'),
                    _buildSettingsCard([
                      _buildSwitchTile(
                        icon: Icons.notifications,
                        title: 'إشعارات الطلبات',
                        subtitle: 'تلقي إشعار عند وصول طلب جديد',
                        value: _orderNotifications,
                        onChanged: (v) => setState(() => _orderNotifications = v),
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        icon: Icons.star,
                        title: 'إشعارات التقييمات',
                        subtitle: 'تلقي إشعار عند تقييم جديد',
                        value: _reviewNotifications,
                        onChanged: (v) => setState(() => _reviewNotifications = v),
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        icon: Icons.campaign,
                        title: 'إشعارات ترويجية',
                        subtitle: 'نصائح وأخبار عن التطبيق',
                        value: _promotionalNotifications,
                        onChanged: (v) => setState(() => _promotionalNotifications = v),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Order Settings
                    _buildSectionTitle('إعدادات الطلبات'),
                    _buildSettingsCard([
                      ListTile(
                        leading: const Icon(Icons.timer, color: _primary),
                        title: const Text('وقت التحضير الافتراضي'),
                        subtitle: Text('$_defaultPrepTime دقيقة'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showPrepTimeDialog,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Account Section
                    _buildSectionTitle('الحساب'),
                    _buildSettingsCard([
                      ListTile(
                        leading: const Icon(Icons.person, color: _primary),
                        title: const Text('تعديل الملف الشخصي'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pushNamed(context, '/chef/edit-profile'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.swap_horiz, color: _primary),
                        title: const Text('التبديل لوضع الزبون'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('تسجيل الخروج',
                            style: TextStyle(color: Colors.red)),
                        onTap: _logout,
                      ),
                    ]),
                    const SizedBox(height: 32),

                    // App Info
                    Center(
                      child: Text(
                        'Diari للطباخين - الإصدار 1.0.0',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: _primary),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: _primary,
    );
  }

  void _showPrepTimeDialog() {
    final times = ['15', '20', '30', '45', '60', '90'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('وقت التحضير الافتراضي', textDirection: TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: times.map((time) => RadioListTile<String>(
            title: Text('$time دقيقة'),
            value: time,
            groupValue: _defaultPrepTime,
            onChanged: (value) {
              setState(() => _defaultPrepTime = value!);
              Navigator.pop(context);
            },
            activeColor: _primary,
          )).toList(),
        ),
      ),
    );
  }
}

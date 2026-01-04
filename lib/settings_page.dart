import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _orderUpdates = true;
  bool _promotions = false;
  String _language = 'العربية';
  String _theme = 'فاتح';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
        _emailNotifications = prefs.getBool('emailNotifications') ?? true;
        _orderUpdates = prefs.getBool('orderUpdates') ?? true;
        _promotions = prefs.getBool('promotions') ?? false;
        _language = prefs.getString('language') ?? 'العربية';
        _theme = prefs.getString('theme') ?? 'فاتح';
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setBool('emailNotifications', _emailNotifications);
      await prefs.setBool('orderUpdates', _orderUpdates);
      await prefs.setBool('promotions', _promotions);
      await prefs.setString('language', _language);
      await prefs.setString('theme', _theme);

      // Update notification subscriptions
      if (_promotions) {
        await NotificationService.subscribeToTopic('promotions');
      } else {
        await NotificationService.unsubscribeFromTopic('promotions');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات'),
            backgroundColor: Colors.green,
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
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'الإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _saveSettings,
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: 'الإشعارات',
              children: [
                _buildSwitchTile(
                  title: 'تفعيل الإشعارات',
                  subtitle: 'استقبال إشعارات حول طلباتك',
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
                _buildSwitchTile(
                  title: 'إشعارات البريد الإلكتروني',
                  subtitle: 'استقبال رسائل على البريد',
                  value: _emailNotifications,
                  onChanged: (val) => setState(() => _emailNotifications = val),
                ),
                _buildSwitchTile(
                  title: 'تحديثات الطلبات',
                  subtitle: 'إشعارات حول حالة طلباتك',
                  value: _orderUpdates,
                  onChanged: (val) => setState(() => _orderUpdates = val),
                ),
                _buildSwitchTile(
                  title: 'العروض والترويجات',
                  subtitle: 'استقبال عروض خاصة وخصومات',
                  value: _promotions,
                  onChanged: (val) => setState(() => _promotions = val),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'اللغة والمظهر',
              children: [
                _buildOptionTile(
                  title: 'اللغة',
                  subtitle: _language,
                  icon: Icons.language,
                  onTap: () => _showLanguageDialog(),
                ),
                _buildOptionTile(
                  title: 'المظهر',
                  subtitle: _theme,
                  icon: Icons.brightness_6,
                  onTap: () => _showThemeDialog(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'الحساب',
              children: [
                _buildOptionTile(
                  title: 'تغيير كلمة المرور',
                  subtitle: 'تحديث كلمة المرور الخاصة بك',
                  icon: Icons.lock_outline,
                  onTap: () => _showChangePasswordDialog(),
                ),
                _buildOptionTile(
                  title: 'حذف الحساب',
                  subtitle: 'حذف حسابك نهائياً',
                  icon: Icons.delete_outline,
                  onTap: () => _showDeleteAccountDialog(),
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'حول التطبيق',
              children: [
                _buildInfoTile(
                  title: 'الإصدار',
                  value: '1.0.0',
                ),
                _buildInfoTile(
                  title: 'شروط الخدمة',
                  value: '',
                  showArrow: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فتح شروط الخدمة')),
                    );
                  },
                ),
                _buildInfoTile(
                  title: 'سياسة الخصوصية',
                  value: '',
                  showArrow: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فتح سياسة الخصوصية')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFEE8C2B),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFFEE8C2B),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: const TextStyle(fontSize: 13))
          : null,
      trailing: const Icon(Icons.arrow_back_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: showArrow
          ? const Icon(Icons.arrow_back_ios, size: 16)
          : Text(value, style: const TextStyle(color: Colors.grey)),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اختر اللغة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('العربية'),
                value: 'العربية',
                groupValue: _language,
                activeColor: const Color(0xFFEE8C2B),
                onChanged: (val) {
                  setState(() => _language = val!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: _language,
                activeColor: const Color(0xFFEE8C2B),
                onChanged: (val) {
                  setState(() => _language = val!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Français'),
                value: 'Français',
                groupValue: _language,
                activeColor: const Color(0xFFEE8C2B),
                onChanged: (val) {
                  setState(() => _language = val!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اختر المظهر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('فاتح'),
                value: 'فاتح',
                groupValue: _theme,
                activeColor: const Color(0xFFEE8C2B),
                onChanged: (val) {
                  setState(() => _theme = val!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('داكن'),
                value: 'داكن',
                groupValue: _theme,
                activeColor: const Color(0xFFEE8C2B),
                onChanged: (val) {
                  setState(() => _theme = val!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('تلقائي'),
                value: 'تلقائي',
                groupValue: _theme,
                activeColor: const Color(0xFFEE8C2B),
                onChanged: (val) {
                  setState(() => _theme = val!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEE8C2B),
              ),
              child: const Text('تغيير'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الحساب'),
          content: const Text(
            'هل أنت متأكد من حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الحساب'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}

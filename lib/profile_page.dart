import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme.dart';
import 'state/app_state.dart';
import 'services/user_service.dart';

const Color _primary = AppColors.primary;

class ProfilePage extends StatefulWidget {
  final bool isChefView;
  
  const ProfilePage({super.key, this.isChefView = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await UserService.getProfile();
      if (response.success && response.data != null && mounted) {
        setState(() {
          _profile = response.data['user'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج', textDirection: TextDirection.rtl),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          textDirection: TextDirection.rtl,
        ),
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
    final user = FirebaseAuth.instance.currentUser;
    final appState = AppState();
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: _primary,
          title: const Text('حسابي'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : RefreshIndicator(
                onRefresh: _loadProfile,
                color: _primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: _primary.withOpacity(0.1),
                              child: Text(
                                (user?.displayName ?? _profile?['name'] ?? 'U')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user?.displayName ?? _profile?['name'] ?? 'المستخدم',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            if (appState.isChef)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.restaurant, size: 16, color: _primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'طباخ',
                                      style: TextStyle(
                                        color: _primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Menu Items
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'تعديل الملف الشخصي',
                        onTap: () async {
                          final result = await Navigator.pushNamed(context, '/edit-profile');
                          if (result == true) {
                            _loadProfile(); // Reload profile after edit
                          }
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'عناويني',
                        onTap: () => Navigator.pushNamed(context, '/addresses'),
                      ),
                      _buildMenuItem(
                        icon: Icons.favorite_outline,
                        title: 'المفضلة',
                        onTap: () => Navigator.pushNamed(context, '/favorites'),
                      ),
                      _buildMenuItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'طلباتي',
                        onTap: () => Navigator.pushNamed(context, '/order-history'),
                      ),
                      _buildMenuItem(
                        icon: Icons.credit_card_outlined,
                        title: 'طرق الدفع',
                        onTap: () => Navigator.pushNamed(context, '/payment'),
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'الإشعارات',
                        onTap: () => Navigator.pushNamed(context, '/notifications'),
                      ),
                      const Divider(height: 32),

                      // Chef Section
                      if (!appState.isChef) ...[
                        _buildMenuItem(
                          icon: Icons.restaurant_menu,
                          title: 'سجل كطباخ',
                          subtitle: 'شارك وصفاتك واكسب المال',
                          onTap: () => Navigator.pushNamed(context, '/chef/signup'),
                          showArrow: true,
                        ),
                        const Divider(height: 32),
                      ],

                      // Switch Views
                      if (appState.isChef && !widget.isChefView)
                        _buildMenuItem(
                          icon: Icons.swap_horiz,
                          title: 'انتقل إلى وضع الطباخ',
                          onTap: () => Navigator.pushReplacementNamed(context, '/chef'),
                        ),
                      if (appState.isChef && widget.isChefView)
                        _buildMenuItem(
                          icon: Icons.swap_horiz,
                          title: 'انتقل إلى وضع الزبون',
                          onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                        ),

                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'الإعدادات',
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'المساعدة والدعم',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('صفحة المساعدة قريباً')),
                          );
                        },
                      ),
                      const Divider(height: 32),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'تسجيل الخروج',
                        textColor: Colors.red,
                        onTap: _logout,
                        showArrow: false,
                      ),
                      const SizedBox(height: 24),

                      // App Version
                      Text(
                        'الإصدار 1.0.0',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: textColor ?? _primary),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: showArrow
            ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400])
            : null,
      ),
    );
  }
}

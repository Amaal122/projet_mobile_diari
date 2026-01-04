import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../theme.dart';
import '../services/chef_service.dart';
import '../services/order_stream_service.dart';
import '../models/chef_profile.dart';

const Color _primary = AppColors.primary;

class ChefDashboardPage extends StatefulWidget {
  const ChefDashboardPage({super.key});

  @override
  State<ChefDashboardPage> createState() => _ChefDashboardPageState();
}

class _ChefDashboardPageState extends State<ChefDashboardPage> {
  bool _isLoading = true;
  ChefStats? _stats;
  ChefProfile? _profile;
  bool _isTogglingAvailability = false;
  StreamSubscription<List<ChefOrderData>>? _ordersSubscription;
  int _liveOrdersCount = 0;
  int _livePendingCount = 0;
  int _livePreparingCount = 0;
  double _liveTodayEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeOrders();
  }
  
  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    int previousPendingCount = 0;

    // Subscribe to all orders to calculate live stats
    _ordersSubscription = OrderStreamService()
        .streamChefOrders(user.uid)
        .listen((orders) {
      if (!mounted) return;
      
      // Calculate live statistics
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final todayOrders = orders.where((o) => 
        o.createdAt.isAfter(today)
      ).toList();
      
      final pendingOrders = orders.where((o) => o.status == 'pending').length;
      final preparingOrders = orders.where((o) => o.status == 'preparing').length;
      final todayEarnings = todayOrders.fold<double>(0, (sum, o) => sum + o.total);
      
      // Check for new pending orders and show notification
      if (pendingOrders > previousPendingCount && previousPendingCount > 0) {
        _showNewOrderNotification();
      }
      previousPendingCount = pendingOrders;
      
      setState(() {
        _liveOrdersCount = todayOrders.length;
        _livePendingCount = pendingOrders;
        _livePreparingCount = preparingOrders;
        _liveTodayEarnings = todayEarnings;
      });
    });
  }

  void _showNewOrderNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('طلب جديد! يرجى مراجعة صفحة الطلبات', style: TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load stats
      final statsResponse = await ChefService.getStats(user.uid);
      if (statsResponse.success) {
        _stats = ChefService.parseStats(statsResponse);
      }

      // Load profile
      final profileResponse = await ChefService.getProfile(user.uid);
      if (profileResponse.success) {
        _profile = ChefService.parseProfile(profileResponse);
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _profile == null) return;

    setState(() => _isTogglingAvailability = true);

    try {
      final newStatus = !_profile!.isActive;
      final response = await ChefService.toggleAvailability(
        userId: user.uid,
        isActive: newStatus,
      );

      if (response.success && mounted) {
        setState(() {
          _profile = _profile!.copyWith(isActive: newStatus);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'أنت الآن متاح للطلبات' : 'أنت غير متاح الآن'),
            backgroundColor: newStatus ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling availability: $e');
    }

    if (mounted) setState(() => _isTogglingAvailability = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: _primary,
        title: Row(
          children: [
            const Text('لوحة التحكم'),
            const Spacer(),
            // Availability toggle
            if (_profile != null)
              GestureDetector(
                onTap: _isTogglingAvailability ? null : _toggleAvailability,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _profile!.isActive 
                        ? Colors.green.withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isTogglingAvailability)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(
                          _profile!.isActive ? Icons.check_circle : Icons.pause_circle,
                          size: 16,
                          color: _profile!.isActive ? Colors.green : Colors.grey,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _profile!.isActive ? 'متاح' : 'غير متاح',
                        style: TextStyle(
                          fontSize: 12,
                          color: _profile!.isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome header
                    Text(
                      'مرحباً، ${_profile?.name ?? 'طباخ'}! 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إليك نظرة عامة على أعمالك اليوم',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'طلبات اليوم',
                          '$_liveOrdersCount',
                          Icons.today,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'طلبات معلقة',
                          '$_livePendingCount',
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'أرباح اليوم',
                          '${_liveTodayEarnings.toStringAsFixed(2)} دت',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'قيد التحضير',
                          '$_livePreparingCount',
                          Icons.restaurant,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'إجراءات سريعة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'إضافة طبق',
                            Icons.add_circle_outline,
                            () => Navigator.pushNamed(context, '/chef/add-dish'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'إدارة الأطباق',
                            Icons.menu_book,
                            () => Navigator.pushNamed(context, '/chef/dishes'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'ملفي الشخصي',
                            Icons.person,
                            () => Navigator.pushNamed(context, '/chef/profile'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'الإعدادات',
                            Icons.settings,
                            () => Navigator.pushNamed(context, '/chef/settings'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Summary Cards
                    const Text(
                      'ملخص الأداء',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),

                    // Switch to Customer View
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('عرض كزبون'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _primary, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'إجمالي الطلبات',
            '${_stats?.totalOrders ?? _liveOrdersCount} طلب',
            Icons.shopping_bag_outlined,
          ),
          const Divider(),
          _buildSummaryRow(
            'إجمالي الأرباح',
            '${(_stats?.totalEarnings ?? _liveTodayEarnings).toStringAsFixed(2)} دت',
            Icons.account_balance_wallet_outlined,
          ),
          const Divider(),
          _buildSummaryRow(
            'عدد الأطباق',
            '${_stats?.dishesCount ?? 0} طبق',
            Icons.restaurant_menu_outlined,
          ),
          const Divider(),
          _buildSummaryRow(
            'التقييم',
            '${(_stats?.averageRating ?? 0.0).toStringAsFixed(1)} ⭐ (${_stats?.reviewsCount ?? 0} تقييم)',
            Icons.star_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 12),
          Text(title),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

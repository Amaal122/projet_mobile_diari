import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../theme.dart';
import '../services/chef_service.dart';
import '../services/chef_review_service.dart';
import '../services/order_stream_service.dart';
import '../services/dish_service.dart' as dish_svc;
import '../widgets/rating_widgets.dart';
import '../widgets/chef_review_widgets.dart';

const Color _primary = AppColors.primary;

/// Enhanced Chef Profile Page with stats, reviews, and settings
class ChefProfilePage extends StatefulWidget {
  final bool isOwnProfile;
  final String? chefId;

  const ChefProfilePage({
    super.key,
    this.isOwnProfile = true,
    this.chefId,
  });

  @override
  State<ChefProfilePage> createState() => _ChefProfilePageState();
}

class _ChefProfilePageState extends State<ChefProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  ChefRatingStats? _ratingStats;
  StreamSubscription<List<ChefOrderData>>? _ordersSubscription;
  int _liveOrdersCount = 0;
  double _liveEarnings = 0.0;
  int _liveDishesCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
    _setupRealtimeStats();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeStats() {
    final userId = widget.chefId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Subscribe to all orders to calculate live stats
    _ordersSubscription = OrderStreamService()
        .streamChefOrders(userId)
        .listen((orders) {
      if (!mounted) return;
      
      final totalOrders = orders.length;
      final totalEarnings = orders.fold<double>(0, (sum, o) => sum + o.total);
      
      setState(() {
        _liveOrdersCount = totalOrders;
        _liveEarnings = totalEarnings;
      });
    });
    
    // Load dishes count
    _loadDishesCount();
  }

  Future<void> _loadDishesCount() async {
    final userId = widget.chefId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final dishes = await dish_svc.DishService.getDishesByCooker(userId);
      if (mounted) {
        setState(() => _liveDishesCount = dishes.length);
      }
    } catch (e) {
      debugPrint('Error loading dishes count: $e');
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final chefId = widget.chefId ?? FirebaseAuth.instance.currentUser?.uid;
    if (chefId == null) return;

    try {
      final response = await ChefService.getProfile(chefId);
      if (response.success && mounted) {
        setState(() => _profile = response.data);
      }

      // Load rating stats
      final stats = await ChefReviewService.getChefRatingStats(chefId);
      if (mounted) {
        setState(() => _ratingStats = stats);
      }
    } catch (e) {
      debugPrint('Error loading chef profile: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : RefreshIndicator(
                onRefresh: _loadProfile,
                color: _primary,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(child: _buildStatsSection()),
                    SliverToBoxAdapter(child: _buildTabBar()),
                    SliverFillRemaining(child: _buildTabContent()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    final name = _profile?['name'] ?? user?.displayName ?? 'طباخ';
    final location = _profile?['location'] ?? '';
    final coverImage = _profile?['coverImage'] ?? '';

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            coverImage.isNotEmpty
                ? Image.network(coverImage, fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_primary, _primary.withOpacity(0.7)],
                      ),
                    ),
                  ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Profile info
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: _primary.withOpacity(0.2),
                      backgroundImage: _profile?['profileImage'] != null
                          ? NetworkImage(_profile!['profileImage'])
                          : null,
                      child: _profile?['profileImage'] == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'T',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (_ratingStats != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            _ratingStats!.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: widget.isOwnProfile
          ? [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editProfile,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, '/chef/settings'),
              ),
            ]
          : null,
    );
  }

  Widget _buildStatsSection() {
    final totalOrders = _liveOrdersCount > 0 ? _liveOrdersCount : (_profile?['totalOrders'] ?? 0);
    final totalDishes = _liveDishesCount > 0 ? _liveDishesCount : (_profile?['totalDishes'] ?? 0);
    final totalEarnings = _liveEarnings > 0 ? _liveEarnings : ((_profile?['totalEarnings'] ?? 0).toDouble());
    final reviewCount = _ratingStats?.totalReviews ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.receipt_long,
            value: '$totalOrders',
            label: 'طلب',
            color: Colors.blue,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.restaurant_menu,
            value: '$totalDishes',
            label: 'طبق',
            color: Colors.orange,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.star,
            value: '$reviewCount',
            label: 'تقييم',
            color: Colors.amber,
          ),
          if (widget.isOwnProfile) ...[
            _buildStatDivider(),
            _buildStatItem(
              icon: Icons.attach_money,
              value: '${totalEarnings.toStringAsFixed(0)}',
              label: 'دت',
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.grey[200],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _primary,
        tabs: const [
          Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard, size: 20)),
          Tab(text: 'التقييمات', icon: Icon(Icons.star, size: 20)),
          Tab(text: 'المعلومات', icon: Icon(Icons.info, size: 20)),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildReviewsTab(),
        _buildInfoTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Card
          if (_ratingStats != null)
            ChefRatingCard(
              chefId: widget.chefId ?? FirebaseAuth.instance.currentUser!.uid,
            ),
          const SizedBox(height: 16),

          // Bio
          if (_profile?['bio'] != null && _profile!['bio'].isNotEmpty) ...[
            const Text(
              'نبذة عني',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_profile!['bio']),
            ),
            const SizedBox(height: 16),
          ],

          // Specialties
          if (_profile?['specialties'] != null &&
              (_profile!['specialties'] as List).isNotEmpty) ...[
            const Text(
              'التخصصات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_profile!['specialties'] as List)
                  .map((s) => Chip(
                        label: Text(s),
                        backgroundColor: _primary.withOpacity(0.1),
                        labelStyle: const TextStyle(color: _primary),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Quick Actions (for own profile)
          if (widget.isOwnProfile) ...[
            const Text(
              'إجراءات سريعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.add_circle,
                    label: 'إضافة طبق',
                    onTap: () => Navigator.pushNamed(context, '/chef/add-dish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.restaurant_menu,
                    label: 'أطباقي',
                    onTap: () => Navigator.pushNamed(context, '/chef/dishes'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: _primary, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    final chefId = widget.chefId ?? FirebaseAuth.instance.currentUser?.uid;
    if (chefId == null) {
      return const Center(child: Text('غير متاح'));
    }

    return ChefReviewsList(chefId: chefId, showHeader: false);
  }

  Widget _buildInfoTab() {
    final phone = _profile?['phone'] ?? '';
    final email = _profile?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
    final location = _profile?['location'] ?? '';
    final workingHours = _profile?['workingHours'] ?? 'غير محدد';
    final joinedAt = _profile?['createdAt'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            items: [
              if (phone.isNotEmpty)
                _InfoItem(icon: Icons.phone, label: 'الهاتف', value: phone),
              if (email.isNotEmpty)
                _InfoItem(icon: Icons.email, label: 'البريد', value: email),
              if (location.isNotEmpty)
                _InfoItem(icon: Icons.location_on, label: 'الموقع', value: location),
              _InfoItem(icon: Icons.access_time, label: 'ساعات العمل', value: workingHours),
              if (joinedAt != null)
                _InfoItem(
                  icon: Icons.calendar_today,
                  label: 'انضم في',
                  value: _formatJoinDate(joinedAt),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required List<_InfoItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: _primary),
                title: Text(item.label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                subtitle: Text(item.value, style: const TextStyle(fontSize: 14)),
              ),
              if (index < items.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatJoinDate(dynamic date) {
    if (date == null) return 'غير معروف';
    try {
      final dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'غير معروف';
    }
  }

  void _editProfile() {
    // Navigate to chef profile edit page
    Navigator.pushNamed(context, '/chef/edit-profile').then((_) => _loadProfile());
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({required this.icon, required this.label, required this.value});
}

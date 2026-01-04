import 'package:flutter/material.dart';
import '../theme.dart';
import 'chef_dashboard_page.dart';
import 'chef_orders_page.dart';
import 'my_dishes_page.dart';
import '../profile_page.dart';

const Color _primary = AppColors.primary;

/// Main scaffold for chef view with bottom navigation
class ChefMainPage extends StatefulWidget {
  const ChefMainPage({super.key});

  @override
  State<ChefMainPage> createState() => _ChefMainPageState();
}

class _ChefMainPageState extends State<ChefMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ChefDashboardPage(),
    const ChefOrdersPage(),
    const MyDishesPage(),
    const ProfilePage(isChefView: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _primary,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'لوحة التحكم',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'الطلبات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu_outlined),
                activeIcon: Icon(Icons.restaurant_menu),
                label: 'أطباقي',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

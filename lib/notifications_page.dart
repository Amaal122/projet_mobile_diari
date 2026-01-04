import 'package:flutter/material.dart';
import 'theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'icon': Icons.local_shipping,
        'title': 'طلبك في الطريق',
        'subtitle': 'كسكسي تقليدي - سيصل خلال 15 دقيقة',
        'time': 'منذ 5 دقائق',
        'read': false,
      },
      {
        'icon': Icons.star,
        'title': 'تقييم جديد',
        'subtitle': 'مريم بن علي قيمت طلبك بـ 5 نجوم',
        'time': 'منذ ساعة',
        'read': false,
      },
      {
        'icon': Icons.local_offer,
        'title': 'عرض خاص',
        'subtitle': 'خصم 20% على جميع الحلويات اليوم',
        'time': 'منذ ساعتين',
        'read': true,
      },
      {
        'icon': Icons.check_circle,
        'title': 'تم التوصيل',
        'subtitle': 'طاجين دجاج - شكراً لطلبك',
        'time': 'أمس',
        'read': true,
      },
      {
        'icon': Icons.chat_bubble,
        'title': 'رسالة جديدة',
        'subtitle': 'علي الغربي: شكراً على تقييمك الرائع',
        'time': 'أمس',
        'read': true,
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'الإشعارات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تمييز جميع الإشعارات كمقروءة'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'تمييز الكل كمقروء',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        body: notifications.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد إشعارات',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: notif['read'] == false
                          ? Colors.white
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEE8C2B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notif['icon'] as IconData,
                          color: const Color(0xFFEE8C2B),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        notif['title'] as String,
                        style: TextStyle(
                          fontWeight: notif['read'] == false
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notif['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif['time'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: notif['read'] == false
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEE8C2B),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

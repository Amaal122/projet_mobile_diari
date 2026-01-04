// Diari - Prototype fidèle au design fourni (Onboarding, Login, Home)
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'onboarding_page.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'cart_page.dart';
import 'checkout_page.dart';
import 'order_success_page.dart';
import 'order_history_page.dart';
import 'order_details_page.dart';
import 'order_tracking_page.dart';
import 'edit_profile_page.dart';
import 'addresses_page.dart';
import 'favorites_page.dart';
import 'main_navigation.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'search_page.dart';
import 'notifications_page.dart';
import 'userinterface.dart' show PaymentPage; // Only import PaymentPage
import 'cooker_messages.dart';
import 'models/cooker.dart';
import 'chef/chef_main_page.dart';
import 'chef/chef_signup_page.dart';
import 'chef/add_dish_page.dart';
import 'chef/my_dishes_page.dart';
import 'chef/chef_profile_page.dart';
import 'chef/chef_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize auth service (sets token if user already logged in)
  await AuthService.initialize();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  runApp(const DiariPrototype());
}

class DiariPrototype extends StatelessWidget {
  const DiariPrototype({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diari Prototype',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const Directionality(
                textDirection: TextDirection.rtl,
                child: OnboardingPage(),
              ),
            );
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainNavigation());
          case '/cart':
            return MaterialPageRoute(builder: (_) => const CartPage());
          case '/checkout':
            return MaterialPageRoute(builder: (_) => const CheckoutPage());
          case '/order-success':
            final orderId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => OrderSuccessPage(orderId: orderId),
            );
          case '/order-history':
            return MaterialPageRoute(builder: (_) => const OrderHistoryPage());
          case '/order-details':
            final orderId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => OrderDetailsPage(orderId: orderId),
            );
          case '/order-tracking':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => OrderTrackingPage(
                orderId: args['orderId'] as String,
                chefName: args['chefName'] as String?,
              ),
            );
          case '/edit-profile':
            return MaterialPageRoute(builder: (_) => const EditProfilePage());
          case '/addresses':
            return MaterialPageRoute(builder: (_) => const AddressesPage());
          case '/favorites':
            return MaterialPageRoute(builder: (_) => const FavoritesPage());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfilePage());
          case '/payment':
            return MaterialPageRoute(builder: (_) => const PaymentPage());
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsPage());
          // Chef routes
          case '/chef':
            return MaterialPageRoute(builder: (_) => const ChefMainPage());
          case '/chef/signup':
            return MaterialPageRoute(builder: (_) => const ChefSignupPage());
          case '/chef/add-dish':
            return MaterialPageRoute(builder: (_) => const AddDishPage());
          case '/chef/dishes':
            return MaterialPageRoute(builder: (_) => const MyDishesPage());
          case '/chef/profile':
            return MaterialPageRoute(builder: (_) => const ChefProfilePage());
          case '/chef/settings':
            return MaterialPageRoute(builder: (_) => const ChefSettingsPage());
          case '/chef/edit-profile':
            return MaterialPageRoute(builder: (_) => const EditProfilePage());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsPage());
          case '/search':
            return MaterialPageRoute(builder: (_) => const SearchPage());
          case '/cooker-messages':
            final args = settings.arguments as Map<String, dynamic>;
            final cooker = Cooker(
              id: args['cookerId'] as String,
              name: args['cookerName'] as String,
              avatarUrl: '',
              location: '',
              rating: 0.0,
              bio: '',
            );
            return MaterialPageRoute(
              builder: (_) => CookerMessagesPage(cooker: cooker),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Directionality(
                textDirection: TextDirection.rtl,
                child: OnboardingPage(),
              ),
            );
        }
      },
    );
  }
}

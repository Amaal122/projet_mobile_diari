# 🍽️ Diari - Home-Cooked Food Delivery Platform

**Diari** is a mobile application that connects home chefs with customers seeking authentic, home-cooked meals. Built with Flutter and Flask, it provides a complete marketplace for discovering, ordering, and delivering homemade food.

---


## �📱 About The Project

Diari bridges the gap between talented home chefs and food lovers looking for authentic, homemade cuisine. The platform enables:

- **Customers**: Browse dishes, place orders, track deliveries, and interact with chefs
- **Chefs**: Manage their menu, receive orders, track analytics, and communicate with customers
- **Admins**: Monitor platform operations, manage users, and handle content moderation

### Key Features

#### For Customers 🛒
- Browse dishes by category and chef
- Real-time cart management
- Secure checkout with multiple payment options
- Order tracking with live status updates
- In-app messaging with chefs
- Favorites and order history
- Push notifications for order updates
- Review and rating system

#### For Chefs 👨‍🍳
- Menu management with image uploads
- Order notifications and management
- Real-time analytics dashboard
- Customer messaging
- Revenue tracking
- Performance insights

#### For Admins 🛡️
- Platform statistics and monitoring
- User and chef management
- Content moderation
- Report handling
- System health monitoring

---

## 🏗️ Architecture

### Tech Stack

**Frontend (Mobile App)**
- **Framework**: Flutter 3.9.2
- **Language**: Dart
- **State Management**: Provider pattern
- **UI Components**: Material Design + Custom widgets
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Notifications**: Firebase Cloud Messaging (FCM)

**Backend (API Server)**
- **Framework**: Flask 3.0.0
- **Language**: Python 3.10+
- **Authentication**: Firebase Admin SDK
- **Database**: Cloud Firestore
- **Storage**: Firebase Cloud Storage
- **APIs**: RESTful API architecture

**Database**
- **Primary**: Cloud Firestore (NoSQL)
- **Collections**: users, dishes, orders, cookers, conversations, messages, reviews, notifications

**Additional Tools**
- **Version Control**: Git & GitHub
- **Testing**: Comprehensive E2E and Unit tests
- **Documentation**: Markdown, API docs

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Mobile App                      │
│  (Customer, Chef & Admin Interfaces)                        │
│                                                              │
│  Pages: Home, Cart, Orders, Messages, Profile, Analytics   │
└─────────────┬────────────────────────────────┬──────────────┘
              │                                │
              │ Firebase Auth                  │ HTTP/REST API
              │ (Authentication)               │ (Business Logic)
              │                                │
              ▼                                ▼
┌─────────────────────────┐      ┌────────────────────────────┐
│   Firebase Services     │      │    Flask Backend Server     │
│                         │      │                             │
│ • Authentication        │      │ • Order Management         │
│ • Cloud Firestore       │◄─────┤ • Cart Operations          │
│ • Cloud Storage         │      │ • Payment Processing       │
│ • Cloud Messaging       │      │ • Notifications            │
│ • Real-time Updates     │      │ • Admin Operations         │
└─────────────────────────┘      │ • Analytics Engine         │
                                 │ • Review Management         │
                                 └────────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

**For Frontend (Flutter App):**
- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio (IDE)

**For Backend (Flask Server):**
- Python 3.10 or higher
- pip (Python package manager)
- Virtual environment (recommended)

**Firebase Setup:**
- Firebase project with Authentication, Firestore, and Storage enabled
- Firebase service account key (JSON file)
- Firebase config for Flutter app

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/Amaal122/projet_mobile_diari.git
cd projet_mobile_diari
```

**⚠️ Important:** Firebase configuration files are not included in the repository for security reasons. Contact the project team to obtain the required configuration files before running the app.

#### 2. Frontend Setup (Flutter)

```bash
# Navigate to project root
cd projet_mobile_diari

# Install Flutter dependencies
flutter pub get

# Check Flutter installation
flutter doctor

# Run on emulator/device
flutter run
```

**Configure Firebase for Flutter:**

Firebase configuration files are required but not included in the repository for security.  
**Required files (contact project team):**

1. `google-services.json` → Place in: `android/app/`
2. `GoogleService-Info.plist` → Place in: `ios/Runner/` (iOS only)
3. `firebase_options.dart` → Place in: `lib/`

#### 3. Backend Setup (Flask)

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
cp .env.example .env
# Edit .env with your configuration

# Add Firebase service account key
# Place serviceAccountKey.json in backend/

# Run the server
python run.py
```

**Backend will start at:** `http://localhost:5000`

#### 4. Environment Variables

Create a `.env` file in the `backend/` directory:

```env
# Flask Configuration
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-secret-key-here

# Firebase
FIREBASE_SERVICE_ACCOUNT_PATH=serviceAccountKey.json

# Server Configuration
HOST=0.0.0.0
PORT=5000
```

---

## 📱 Running the Application

### Run Frontend (Flutter App)

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices                    # List available devices
flutter run -d <device-id>

# Run on Chrome (web)
flutter run -d chrome

# Build APK for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

### Run Backend (Flask Server)

```bash
# Development mode
cd backend
python run.py

# The server will be available at:
# http://localhost:5000
# API base URL: http://localhost:5000/api
# Health check: http://localhost:5000/api/health
```

### Running Tests

**Backend Tests:**

```bash
cd backend

# Run E2E integration tests (32 tests)
python comprehensive_test.py

# Run unit tests (47 tests)
python tests/run_unit_tests.py

# Both test suites should show high pass rates (90%+)
```

**Frontend Tests:**
```bash
# Run Flutter tests (if available)
flutter test
```

---

## 📂 Project Structure

```
diari-app/
├── android/                    # Android native code
├── ios/                       # iOS native code
├── lib/                       # Flutter application code
│   ├── main.dart             # App entry point
│   ├── models/               # Data models
│   ├── services/             # API services, Firebase
│   ├── state/                # State management
│   ├── widgets/              # Reusable widgets
│   ├── chef/                 # Chef-specific pages
│   ├── *_page.dart           # Application pages
│   └── theme.dart            # App theming
│
├── backend/                   # Flask backend server
│   ├── application.py        # Main application factory
│   ├── run.py                # Server entry point
│   ├── requirements.txt      # Python dependencies
│   ├── .env.example          # Environment template
│   ├── app/
│   │   ├── routes/          # API endpoints
│   │   │   ├── auth_routes.py       # Authentication
│   │   │   ├── order_routes.py      # Order management
│   │   │   ├── cart_routes.py       # Shopping cart
│   │   │   ├── dish_routes.py       # Dish operations
│   │   │   ├── review_routes.py     # Reviews & ratings
│   │   │   ├── message_routes.py    # Messaging
│   │   │   ├── notification_routes.py # Push notifications
│   │   │   ├── payment_routes.py    # Payment processing
│   │   │   ├── admin_routes.py      # Admin operations
│   │   │   ├── analytics_routes.py  # Chef analytics
│   │   │   └── upload_routes.py     # Image uploads
│   │   │
│   │   ├── services/        # Business logic
│   │   │   ├── firebase_service.py  # Firebase integration
│   │   │   └── auto_notifications.py # Notification engine
│   │   │
│   │   └── utils/           # Utilities
│   │       └── error_handler.py     # Error handling
│   │
│   ├── tests/               # Unit tests (47 tests)
│   ├── comprehensive_test.py # E2E tests (32 tests)
│   ├── scripts/             # Utility scripts
│   └── API_DOCUMENTATION.md # Complete API reference
│
├── assets/                   # Images, fonts, icons
├── pubspec.yaml             # Flutter dependencies
├── firebase.json            # Firebase configuration
└── README.md                # This file
```

---

## 🔌 API Documentation

The backend provides a comprehensive REST API with 55+ endpoints organized by functionality.

### Base URL
```
http://localhost:5000/api
```

### Main Endpoint Categories

1. **Authentication** (`/auth`)
   - Verify Firebase tokens
   - Get user profile

2. **Orders** (`/orders`)
   - Create, read, update orders
   - Chef order management
   - Order status tracking

3. **Cart** (`/cart`)
   - Add/remove items
   - Update quantities
   - Clear cart

4. **Dishes** (`/dishes`)
   - Browse dishes
   - Search and filter
   - Category-based viewing

5. **Reviews** (`/reviews`)
   - Submit reviews
   - Edit/delete reviews
   - Report reviews

6. **Messages** (`/messages`)
   - Send/receive messages
   - Conversation management

7. **Notifications** (`/notifications`)
   - Get notifications
   - Mark as read
   - Push notification management

8. **Analytics** (`/analytics`)
   - Chef dashboard data
   - Revenue charts
   - Customer insights

9. **Admin** (`/admin`)
   - Platform statistics
   - User management
   - Content moderation

10. **Upload** (`/upload`)
    - Image uploads
    - File management

**Full API documentation:** See [backend/API_DOCUMENTATION.md](backend/API_DOCUMENTATION.md)

---

## 🧪 Testing

### Test Coverage

#### Backend Tests
- **E2E Tests**: 32 comprehensive tests (100% pass rate)
- **Unit Tests**: 47 tests across 5 modules (91.5% pass rate)
- **Total Coverage**: ~95%

#### Test Categories
- Authentication & Authorization
- Order workflow (create → accept → deliver)
- Cart operations
- Payment processing
- Messaging system
- Admin operations
- Analytics endpoints
- Error handling

**Detailed test report:** See [backend/TESTING_REPORT.md](backend/TESTING_REPORT.md)

---

## 👥 User Roles

### Customer
- Browse and order dishes
- Track order status
- Message chefs
- Leave reviews
- Manage favorites

### Chef (Cooker)
- Create and manage dishes
- Accept/reject orders
- Update order status
- View analytics
- Message customers

### Admin
- Monitor platform health
- Manage users and chefs
- Handle reports
- View system analytics
- Content moderation

---

## 🔐 Security Features

- Firebase Authentication for secure login
- JWT token validation on backend
- Role-based access control (Customer, Chef, Admin)
- Rate limiting (100 requests/minute per IP)
- Input validation and sanitization
- Secure file uploads with validation
- CORS protection
- Error handling with sanitized responses

---

## 🚧 Known Issues & Limitations

- APK size optimization needed
- Offline mode not fully implemented
- Payment integration uses mock for development
- Some unit tests have mock setup issues (non-critical)

---

## 🗺️ Roadmap

### Future Enhancements
- [ ] Real-time order tracking with maps
- [ ] Advanced search with Elasticsearch
- [ ] WebSocket for live updates
- [ ] Email notifications with Celery
- [ ] Redis caching for performance
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Chef verification system
- [ ] Loyalty points program

---

## 📄 License

This project is developed as part of a university mobile development course.

---

## 👨‍💻 Development Team

- Amal BOUGUILA
- Eslem BEN AMEUR
- Fedi HAJ TAIEB
- Mahmoud FOURATI
- Nesrine HAMROUNI

---

## 🙏 Acknowledgments

- Flutter framework and community
- Firebase platform
- Flask framework
- All open-source libraries used in this project

---

**Built with ❤️ for food lovers and home chefs**

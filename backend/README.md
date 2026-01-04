"""
Diari Backend
=============
Flask + Firebase Hybrid Backend

Structure:
├── application.py          # Main application factory
├── run.py                  # Entry point to start server
├── requirements.txt        # Python dependencies
├── .env.example           # Environment variables template
├── firebase-credentials.json  # Firebase service account (get from Firebase Console)
└── app/
    ├── __init__.py
    ├── routes/
    │   ├── auth_routes.py   # Token verification
    │   ├── order_routes.py  # Order CRUD
    │   ├── cart_routes.py   # Shopping cart
    │   └── user_routes.py   # Profile, addresses, favorites
    └── services/
        └── firebase_service.py  # Firebase Admin SDK

Setup:
1. Copy .env.example to .env
2. Download Firebase credentials from Firebase Console
3. pip install -r requirements.txt
4. python run.py

API Endpoints:
- GET  /api/health              - Health check
- POST /api/auth/verify         - Verify Firebase token
- GET  /api/auth/profile        - Get user profile (from Firebase Auth)
- GET  /api/orders              - Get user's orders
- POST /api/orders              - Create order
- GET  /api/orders/<id>         - Get single order
- POST /api/orders/<id>/cancel  - Cancel order
- GET  /api/cart                - Get cart
- POST /api/cart/add            - Add to cart
- PUT  /api/cart/update         - Update cart item
- DELETE /api/cart/remove/<id>  - Remove from cart
- DELETE /api/cart/clear        - Clear cart
- GET  /api/users/profile       - Get user profile (from Firestore)
- PUT  /api/users/profile       - Update profile
- GET  /api/users/addresses     - Get addresses
- POST /api/users/addresses     - Add address
- DELETE /api/users/addresses/<id> - Delete address
- GET  /api/users/favorites     - Get favorites
- POST /api/users/favorites/<id> - Add favorite
- DELETE /api/users/favorites/<id> - Remove favorite
"""

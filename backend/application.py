"""
Diari Backend - Flask + Firebase Hybrid
========================================
Handles: Orders, Payments, Cart, Notifications
Firebase handles: Auth, Dishes/Cookers data (read-heavy)
"""

import os
from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Simple in-memory rate limiting
from collections import defaultdict
from time import time

request_counts = defaultdict(list)

def create_app():
    """Application factory pattern"""
    app = Flask(__name__)
    
    # Configuration
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
    app.config['RATELIMIT_ENABLED'] = True
    app.config['RATELIMIT_STORAGE_URL'] = 'memory://'
    
    # Enable CORS for Flutter app - more permissive for web development
    CORS(app, 
         origins=["*"],
         allow_headers=["Content-Type", "Authorization", "Accept", "Origin", "X-Requested-With"],
         methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
         supports_credentials=True,
         expose_headers=["Content-Type", "Authorization"]
    )
    
    # Simple rate limiting middleware
    @app.before_request
    def rate_limit():
        from flask import request, jsonify
        if request.method == 'OPTIONS':
            return None
        
        client_ip = request.remote_addr
        current_time = time()
        
        # Clean old requests (older than 1 minute)
        request_counts[client_ip] = [t for t in request_counts[client_ip] if current_time - t < 60]
        
        # Check if rate limit exceeded (100 requests per minute)
        if len(request_counts[client_ip]) >= 100:
            return jsonify({'error': 'Rate limit exceeded. Please try again later.'}), 429
        
        request_counts[client_ip].append(current_time)
        return None
    
    # Handle preflight OPTIONS requests
    @app.after_request
    def after_request(response):
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization,Accept,Origin,X-Requested-With')
        response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS,PATCH')
        response.headers.add('Access-Control-Allow-Credentials', 'true')
        return response
    
    # Initialize Firebase
    from app.services.firebase_service import init_firebase
    init_firebase()
    
    # Register error handlers
    from app.utils.error_handler import register_error_handlers
    register_error_handlers(app)
    
    # Register blueprints (routes)
    from app.routes.auth_routes import auth_bp
    from app.routes.order_routes import order_bp
    from app.routes.cart_routes import cart_bp
    from app.routes.user_routes import user_bp
    from app.routes.review_routes import review_bp
    from app.routes.message_routes import message_bp
    from app.routes.cooker_routes import cooker_bp
    from app.routes.dish_routes import dish_bp
    from app.routes.notification_routes import notification_bp
    from app.routes.payment_routes import payment_bp
    from app.routes.admin_routes import admin_bp
    from app.routes.analytics_routes import analytics_bp
    from app.routes.upload_routes import upload_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(order_bp, url_prefix='/api/orders')
    app.register_blueprint(cart_bp, url_prefix='/api/cart')
    app.register_blueprint(user_bp, url_prefix='/api/users')
    app.register_blueprint(review_bp, url_prefix='/api/reviews')
    app.register_blueprint(message_bp, url_prefix='/api/messages')
    app.register_blueprint(cooker_bp, url_prefix='/api/cookers')
    app.register_blueprint(dish_bp, url_prefix='/api/dishes')
    app.register_blueprint(notification_bp, url_prefix='/api/notifications')
    app.register_blueprint(payment_bp, url_prefix='/api/payments')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')
    app.register_blueprint(analytics_bp, url_prefix='/api/analytics')
    app.register_blueprint(upload_bp, url_prefix='/api/upload')
    
    # Health check endpoint
    @app.route('/api/health')
    def health():
        return {'status': 'healthy', 'service': 'diari-backend'}
    
    return app


if __name__ == '__main__':
    app = create_app()
    app.run(
        host=os.getenv('HOST', '0.0.0.0'),
        port=int(os.getenv('PORT', 5000)),
        debug=os.getenv('FLASK_DEBUG', 'True') == 'True'
    )

"""
Authentication Routes
=====================
Handles token verification and user session management
(Firebase Auth is used directly from Flutter, this verifies tokens server-side)
"""

from flask import Blueprint, request, jsonify
from functools import wraps
from app.services.firebase_service import verify_token, get_user_by_uid, get_db

auth_bp = Blueprint('auth', __name__)


def require_auth(f):
    """Decorator to require valid Firebase token"""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        
        if not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Missing or invalid authorization header'}), 401
        
        token = auth_header.split('Bearer ')[1]
        decoded = verify_token(token)
        
        if not decoded:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Add user info to request context
        request.user = decoded
        return f(*args, **kwargs)
    
    return decorated


def require_chef(f):
    """Decorator to require chef/cooker role"""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        
        if not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Missing or invalid authorization header'}), 401
        
        token = auth_header.split('Bearer ')[1]
        decoded = verify_token(token)
        
        if not decoded:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Check if user is a chef
        db = get_db()
        if db:
            chef_doc = db.collection('cookers').document(decoded.get('uid')).get()
            if not chef_doc.exists:
                return jsonify({'error': 'Access denied. Chef account required.'}), 403
            
            request.user = decoded
            request.chef = chef_doc.to_dict()
            return f(*args, **kwargs)
        
        return jsonify({'error': 'Database unavailable'}), 503
    
    return decorated


def require_admin(f):
    """Decorator to require admin role"""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        
        if not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Missing or invalid authorization header'}), 401
        
        token = auth_header.split('Bearer ')[1]
        decoded = verify_token(token)
        
        if not decoded:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Check if user is admin
        db = get_db()
        if db:
            user_doc = db.collection('users').document(decoded.get('uid')).get()
            if not user_doc.exists:
                return jsonify({'error': 'User not found'}), 404
            
            user_data = user_doc.to_dict()
            if not user_data.get('isAdmin', False):
                return jsonify({'error': 'Access denied. Admin privileges required.'}), 403
            
            request.user = decoded
            request.admin = user_data
            return f(*args, **kwargs)
        
        return jsonify({'error': 'Database unavailable'}), 503
    
    return decorated


@auth_bp.route('/verify', methods=['POST'])
def verify_user_token():
    """
    Verify Firebase ID token
    Called after Flutter Firebase Auth to validate server-side
    """
    data = request.get_json()
    token = data.get('token')
    
    if not token:
        return jsonify({'error': 'Token required'}), 400
    
    decoded = verify_token(token)
    
    if decoded:
        return jsonify({
            'valid': True,
            'uid': decoded.get('uid'),
            'email': decoded.get('email'),
            'name': decoded.get('name', '')
        })
    else:
        return jsonify({'valid': False, 'error': 'Invalid token'}), 401


@auth_bp.route('/profile', methods=['GET'])
@require_auth
def get_profile():
    """Get current user profile"""
    uid = request.user.get('uid')
    user = get_user_by_uid(uid)
    
    if user:
        return jsonify({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.display_name,
            'phoneNumber': user.phone_number,
            'photoUrl': user.photo_url
        })
    else:
        return jsonify({'error': 'User not found'}), 404

"""
User Routes
============
Handles user profile, addresses, favorites
"""

from flask import Blueprint, request, jsonify
from datetime import datetime
from app.routes.auth_routes import require_auth
from app.services.firebase_service import get_db

user_bp = Blueprint('users', __name__)


@user_bp.route('/profile', methods=['GET'])
@require_auth
def get_user_profile():
    """Get user profile from Firestore"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        doc = db.collection('users').document(uid).get()
        
        if doc.exists:
            return jsonify(doc.to_dict())
        else:
            # Return basic info from token
            return jsonify({
                'uid': uid,
                'email': request.user.get('email'),
                'name': request.user.get('name', ''),
                'phone': '',
                'addresses': [],
                'favorites': []
            })
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@user_bp.route('/profile', methods=['PUT'])
@require_auth
def update_user_profile():
    """
    Update user profile
    Expected body: { name, phone, photoUrl }
    """
    data = request.get_json()
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        user_ref = db.collection('users').document(uid)
        
        update_data = {
            'updatedAt': datetime.utcnow()
        }
        
        # Only update provided fields
        allowed_fields = ['name', 'phone', 'photoUrl']
        for field in allowed_fields:
            if field in data:
                update_data[field] = data[field]
        
        user_ref.set(update_data, merge=True)
        
        return jsonify({
            'success': True,
            'message': 'تم تحديث الملف الشخصي'
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503


# ==================== ADDRESSES ====================

@user_bp.route('/addresses', methods=['GET'])
@require_auth
def get_addresses():
    """Get user's saved addresses"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        doc = db.collection('users').document(uid).get()
        
        if doc.exists:
            addresses = doc.to_dict().get('addresses', [])
            return jsonify({'addresses': addresses})
        else:
            return jsonify({'addresses': []})
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@user_bp.route('/addresses', methods=['POST'])
@require_auth
def add_address():
    """
    Add new address
    Expected body: { label, address, city, isDefault }
    """
    data = request.get_json()
    uid = request.user.get('uid')
    
    if not data.get('address'):
        return jsonify({'error': 'Address is required'}), 400
    
    db = get_db()
    if db:
        user_ref = db.collection('users').document(uid)
        doc = user_ref.get()
        
        if doc.exists:
            addresses = doc.to_dict().get('addresses', [])
        else:
            addresses = []
        
        new_address = {
            'id': f'addr_{len(addresses) + 1}',
            'label': data.get('label', 'المنزل'),
            'address': data['address'],
            'city': data.get('city', ''),
            'isDefault': data.get('isDefault', len(addresses) == 0),
            'createdAt': datetime.utcnow().isoformat()
        }
        
        # If new address is default, unset others
        if new_address['isDefault']:
            for addr in addresses:
                addr['isDefault'] = False
        
        addresses.append(new_address)
        
        user_ref.set({'addresses': addresses}, merge=True)
        
        return jsonify({
            'success': True,
            'address': new_address,
            'message': 'تم إضافة العنوان'
        }), 201
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@user_bp.route('/addresses/<address_id>', methods=['DELETE'])
@require_auth
def delete_address(address_id):
    """Delete an address"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        user_ref = db.collection('users').document(uid)
        doc = user_ref.get()
        
        if not doc.exists:
            return jsonify({'error': 'User not found'}), 404
        
        addresses = doc.to_dict().get('addresses', [])
        addresses = [addr for addr in addresses if addr.get('id') != address_id]
        
        user_ref.set({'addresses': addresses}, merge=True)
        
        return jsonify({
            'success': True,
            'message': 'تم حذف العنوان'
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503


# ==================== FAVORITES ====================

@user_bp.route('/favorites', methods=['GET'])
@require_auth
def get_favorites():
    """Get user's favorite dishes"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        doc = db.collection('users').document(uid).get()
        
        if doc.exists:
            favorites = doc.to_dict().get('favorites', [])
            return jsonify({'favorites': favorites})
        else:
            return jsonify({'favorites': []})
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@user_bp.route('/favorites/<dish_id>', methods=['POST'])
@require_auth
def add_favorite(dish_id):
    """Add dish to favorites"""
    uid = request.user.get('uid')
    data = request.get_json() or {}
    
    db = get_db()
    if db:
        user_ref = db.collection('users').document(uid)
        doc = user_ref.get()
        
        if doc.exists:
            favorites = doc.to_dict().get('favorites', [])
        else:
            favorites = []
        
        # Check if already favorited
        if any(f.get('dishId') == dish_id for f in favorites):
            return jsonify({'message': 'Already in favorites'}), 200
        
        favorites.append({
            'dishId': dish_id,
            'dishName': data.get('dishName', ''),
            'dishImage': data.get('dishImage', ''),
            'addedAt': datetime.utcnow().isoformat()
        })
        
        user_ref.set({'favorites': favorites}, merge=True)
        
        return jsonify({
            'success': True,
            'message': 'تمت الإضافة إلى المفضلة'
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@user_bp.route('/favorites/<dish_id>', methods=['DELETE'])
@require_auth
def remove_favorite(dish_id):
    """Remove dish from favorites"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        user_ref = db.collection('users').document(uid)
        doc = user_ref.get()
        
        if not doc.exists:
            return jsonify({'error': 'User not found'}), 404
        
        favorites = doc.to_dict().get('favorites', [])
        favorites = [f for f in favorites if f.get('dishId') != dish_id]
        
        user_ref.set({'favorites': favorites}, merge=True)
        
        return jsonify({
            'success': True,
            'message': 'تمت الإزالة من المفضلة'
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503

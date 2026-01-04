"""
Cart Routes
============
Handles shopping cart operations (stored in Firestore per user)
"""

from flask import Blueprint, request, jsonify
from datetime import datetime
from app.routes.auth_routes import require_auth
from app.services.firebase_service import get_db

cart_bp = Blueprint('cart', __name__)


@cart_bp.route('/', methods=['GET'])
@require_auth
def get_cart():
    """Get current user's cart"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        doc = db.collection('carts').document(uid).get()
        
        if doc.exists:
            cart_data = doc.to_dict()
            return jsonify(cart_data)
        else:
            return jsonify({'items': [], 'total': 0})
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@cart_bp.route('/add', methods=['POST'])
@require_auth
def add_to_cart():
    """
    Add item to cart
    Expected body: {
        dishId: string,
        dishName: string (optional - will fetch from dish if missing),
        dishImage: string (optional),
        price: number (optional - will fetch from dish if missing),
        quantity: number,
        cookerId: string (optional),
        cookerName: string (optional)
    }
    """
    data = request.get_json()
    uid = request.user.get('uid')
    
    # Only dishId and quantity are truly required
    if 'dishId' not in data or 'quantity' not in data:
        return jsonify({'error': 'dishId and quantity are required'}), 400
    
    # Validate quantity
    if data['quantity'] <= 0:
        return jsonify({'error': 'quantity must be greater than 0'}), 400
    
    db = get_db()
    if db:
        # If dish details not provided, fetch from database
        if 'dishName' not in data or 'price' not in data:
            dish_doc = db.collection('dishes').document(data['dishId']).get()
            if not dish_doc.exists:
                return jsonify({'error': 'Dish not found'}), 404
            
            dish_data = dish_doc.to_dict()
            data['dishName'] = data.get('dishName', dish_data.get('name', 'Unknown'))
            data['price'] = data.get('price', dish_data.get('price', 0))
            data['dishImage'] = data.get('dishImage', dish_data.get('image', ''))
            data['cookerId'] = data.get('cookerId', dish_data.get('cookerId', ''))
            
            # Get cooker name if needed
            if 'cookerName' not in data and data['cookerId']:
                cooker_doc = db.collection('cookers').document(data['cookerId']).get()
                if cooker_doc.exists:
                    data['cookerName'] = cooker_doc.to_dict().get('name', '')
        
        cart_ref = db.collection('carts').document(uid)
        cart_doc = cart_ref.get()
        
        if cart_doc.exists:
            cart_data = cart_doc.to_dict()
            items = cart_data.get('items', [])
        else:
            items = []
        
        # Check if item already exists
        existing_index = None
        for i, item in enumerate(items):
            if item.get('dishId') == data['dishId']:
                existing_index = i
                break
        
        if existing_index is not None:
            # Update quantity
            items[existing_index]['quantity'] += data['quantity']
        else:
            # Add new item
            items.append({
                'dishId': data['dishId'],
                'dishName': data['dishName'],
                'dishImage': data.get('dishImage', ''),
                'price': data['price'],
                'quantity': data['quantity'],
                'cookerId': data.get('cookerId', ''),
                'cookerName': data.get('cookerName', ''),
                'addedAt': datetime.utcnow().isoformat()
            })
        
        # Calculate total
        total = sum(item['price'] * item['quantity'] for item in items)
        
        cart_ref.set({
            'items': items,
            'total': total,
            'updatedAt': datetime.utcnow()
        })
        
        return jsonify({
            'success': True,
            'itemCount': len(items),
            'total': total,
            'message': 'تمت الإضافة إلى السلة'
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@cart_bp.route('/update', methods=['PUT'])
@require_auth
def update_cart_item():
    """
    Update item quantity in cart
    Expected body: { dishId: string, quantity: number }
    """
    data = request.get_json()
    uid = request.user.get('uid')
    
    if 'dishId' not in data or 'quantity' not in data:
        return jsonify({'error': 'dishId and quantity required'}), 400
    
    db = get_db()
    if db:
        cart_ref = db.collection('carts').document(uid)
        cart_doc = cart_ref.get()
        
        if not cart_doc.exists:
            return jsonify({'error': 'Cart not found'}), 404
        
        cart_data = cart_doc.to_dict()
        items = cart_data.get('items', [])
        
        # Find and update item
        item_found = False
        for item in items:
            if item.get('dishId') == data['dishId']:
                if data['quantity'] <= 0:
                    items.remove(item)
                else:
                    item['quantity'] = data['quantity']
                item_found = True
                break
        
        if not item_found:
            return jsonify({'error': 'Item not in cart'}), 404
        
        total = sum(item['price'] * item['quantity'] for item in items)
        
        cart_ref.set({
            'items': items,
            'total': total,
            'updatedAt': datetime.utcnow()
        })
        
        return jsonify({
            'success': True,
            'itemCount': len(items),
            'total': total
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@cart_bp.route('/remove/<dish_id>', methods=['DELETE'])
@require_auth
def remove_from_cart(dish_id):
    """Remove item from cart"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        cart_ref = db.collection('carts').document(uid)
        cart_doc = cart_ref.get()
        
        if not cart_doc.exists:
            return jsonify({'error': 'Cart not found'}), 404
        
        cart_data = cart_doc.to_dict()
        items = [item for item in cart_data.get('items', []) 
                 if item.get('dishId') != dish_id]
        
        total = sum(item['price'] * item['quantity'] for item in items)
        
        cart_ref.set({
            'items': items,
            'total': total,
            'updatedAt': datetime.utcnow()
        })
        
        return jsonify({
            'success': True,
            'itemCount': len(items),
            'total': total,
            'message': 'تمت الإزالة من السلة'
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@cart_bp.route('/clear', methods=['DELETE'])
@require_auth
def clear_cart():
    """Clear entire cart"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        db.collection('carts').document(uid).delete()
        return jsonify({
            'success': True,
            'message': 'تم تفريغ السلة'
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503

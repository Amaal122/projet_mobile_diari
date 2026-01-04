"""
Order Routes
=============
Handles order creation, status updates, and order history
"""

from flask import Blueprint, request, jsonify
from datetime import datetime
from app.routes.auth_routes import require_auth
from app.services.firebase_service import get_db
from app.services.auto_notifications import handle_order_status_change

order_bp = Blueprint('orders', __name__)


@order_bp.route('/', methods=['POST'])
@require_auth
def create_order():
    """
    Create a new order
    Expected body: {
        items: [{dishId, dishName, quantity, price, cookerId, cookerName}],
        deliveryAddress: string,
        deliveryNotes: string,
        paymentMethod: 'cash' | 'card'
    }
    """
    data = request.get_json()
    uid = request.user.get('uid')
    
    # Validate required fields
    if not data.get('items') or len(data['items']) == 0:
        return jsonify({'error': 'Order must have at least one item'}), 400
    
    if not data.get('deliveryAddress'):
        return jsonify({'error': 'Delivery address is required'}), 400
    
    # Calculate totals
    subtotal = sum(item['price'] * item['quantity'] for item in data['items'])
    delivery_fee = 3.0  # TND - could be dynamic based on distance
    total = subtotal + delivery_fee
    
    # Create order document
    order = {
        'userId': uid,
        'userEmail': request.user.get('email'),
        'items': data['items'],
        'subtotal': subtotal,
        'deliveryFee': delivery_fee,
        'total': total,
        'deliveryAddress': data['deliveryAddress'],
        'deliveryNotes': data.get('deliveryNotes', ''),
        'paymentMethod': data.get('paymentMethod', 'cash'),
        'status': 'pending',  # pending -> confirmed -> preparing -> on_the_way -> delivered
        'createdAt': datetime.utcnow(),
        'updatedAt': datetime.utcnow()
    }
    
    db = get_db()
    if db:
        doc_ref = db.collection('orders').add(order)
        order_id = doc_ref[1].id
        
        # Send auto-notification to chef
        try:
            handle_order_status_change(order_id, None, 'pending', order)
        except Exception as e:
            print(f"Failed to send order notification: {e}")
        
        return jsonify({
            'success': True,
            'orderId': order_id,
            'total': total,
            'message': 'تم إنشاء الطلب بنجاح'
        }), 201
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@order_bp.route('/', methods=['GET'])
@require_auth
def get_user_orders():
    """Get all orders for current user"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        try:
            # Simple query without orderBy to avoid composite index requirement
            orders_ref = db.collection('orders')\
                .where('userId', '==', uid)\
                .stream()
            
            orders = []
            for doc in orders_ref:
                order_data = doc.to_dict()
                order_data['id'] = doc.id
                # Convert timestamps
                if order_data.get('createdAt'):
                    order_data['createdAt'] = order_data['createdAt'].isoformat() if hasattr(order_data['createdAt'], 'isoformat') else str(order_data['createdAt'])
                if order_data.get('updatedAt'):
                    order_data['updatedAt'] = order_data['updatedAt'].isoformat() if hasattr(order_data['updatedAt'], 'isoformat') else str(order_data['updatedAt'])
                orders.append(order_data)
            
            # Sort in Python instead of Firestore
            orders.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
            
            return jsonify({'orders': orders[:50]})  # Limit to 50
        except Exception as e:
            print(f"Error getting orders: {e}")
            return jsonify({'error': str(e)}), 500
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@order_bp.route('/<order_id>', methods=['GET'])
@require_auth
def get_order(order_id):
    """Get single order by ID"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        doc = db.collection('orders').document(order_id).get()
        
        if not doc.exists:
            return jsonify({'error': 'Order not found'}), 404
        
        order_data = doc.to_dict()
        
        # Verify ownership
        if order_data.get('userId') != uid:
            return jsonify({'error': 'Unauthorized'}), 403
        
        order_data['id'] = doc.id
        if order_data.get('createdAt'):
            order_data['createdAt'] = order_data['createdAt'].isoformat()
        if order_data.get('updatedAt'):
            order_data['updatedAt'] = order_data['updatedAt'].isoformat()
        
        return jsonify(order_data)
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@order_bp.route('/<order_id>/cancel', methods=['POST'])
@require_auth
def cancel_order(order_id):
    """Cancel an order (only if still pending)"""
    uid = request.user.get('uid')
    
    db = get_db()
    if db:
        doc_ref = db.collection('orders').document(order_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return jsonify({'error': 'Order not found'}), 404
        
        order_data = doc.to_dict()
        
        if order_data.get('userId') != uid:
            return jsonify({'error': 'Unauthorized'}), 403
        
        if order_data.get('status') != 'pending':
            return jsonify({'error': 'Only pending orders can be cancelled'}), 400
        
        doc_ref.update({
            'status': 'cancelled',
            'cancelledBy': uid,
            'updatedAt': datetime.utcnow()
        })
        
        # Send cancellation notification
        order_data['cancelledBy'] = uid
        try:
            handle_order_status_change(order_id, 'pending', 'cancelled', order_data)
        except Exception as e:
            print(f"Failed to send cancellation notification: {e}")
        
        return jsonify({
            'success': True,
            'message': 'تم إلغاء الطلب بنجاح'
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503


@order_bp.route('/<order_id>/status', methods=['PUT'])
@require_auth
def update_order_status(order_id):
    """Update order status (for chef/admin)"""
    uid = request.user.get('uid')
    data = request.get_json()
    new_status = data.get('status')
    
    valid_statuses = ['pending', 'accepted', 'preparing', 'ready', 'on_the_way', 'delivered', 'cancelled']
    if new_status not in valid_statuses:
        return jsonify({'error': f'Invalid status. Must be one of: {valid_statuses}'}), 400
    
    db = get_db()
    if db:
        doc_ref = db.collection('orders').document(order_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return jsonify({'error': 'Order not found'}), 404
        
        order_data = doc.to_dict()
        
        # Check if user is the chef for this order or the customer
        items = order_data.get('items', [])
        chef_ids = set(item.get('cookerId', '') for item in items)
        
        # Allow if user is customer (for cancellation) or chef (for status updates)
        if uid != order_data.get('userId') and uid not in chef_ids:
            # Check if user is a registered cooker
            cooker_doc = db.collection('cookers').document(uid).get()
            if not cooker_doc.exists:
                return jsonify({'error': 'Unauthorized'}), 403
        
        old_status = order_data.get('status')
        
        doc_ref.update({
            'status': new_status,
            'updatedAt': datetime.utcnow()
        })
        
        # Send auto-notification
        try:
            order_data['status'] = new_status
            handle_order_status_change(order_id, old_status, new_status, order_data)
        except Exception as e:
            print(f"Failed to send status change notification: {e}")
        
        return jsonify({
            'success': True,
            'message': f'Order status updated to {new_status}',
            'status': new_status
        })
    else:
        return jsonify({'error': 'Database unavailable'}), 503

"""
Cooker/Chef routes for Diari app
Handles chef registration, profile, dishes, and order management
"""
from flask import Blueprint, request, jsonify
from firebase_admin import firestore
from datetime import datetime

cooker_bp = Blueprint('cooker', __name__)
db = firestore.client()

# ============== CHEF REGISTRATION & PROFILE ==============

@cooker_bp.route('/register', methods=['POST'])
def register_chef():
    """Register a user as a chef/cooker"""
    try:
        data = request.json
        user_id = data.get('userId')
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        # Check if user exists, create if not
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            # Create user document if it doesn't exist (user authenticated via Firebase Auth)
            user_ref.set({
                'id': user_id,
                'name': data.get('name', ''),
                'email': '',
                'phone': data.get('phone', ''),
                'role': 'customer',
                'createdAt': datetime.utcnow().isoformat(),
                'updatedAt': datetime.utcnow().isoformat(),
            })
        
        # Create chef profile
        chef_data = {
            'userId': user_id,
            'name': data.get('name', ''),
            'bio': data.get('bio', ''),
            'phone': data.get('phone', ''),
            'specialties': data.get('specialties', []),
            'location': data.get('location', ''),
            'address': data.get('address', ''),
            'profileImage': data.get('profileImage', ''),
            'isActive': True,
            'isVerified': False,
            'rating': 0.0,
            'totalOrders': 0,
            'totalEarnings': 0.0,
            'workingHours': data.get('workingHours', {
                'monday': {'open': '09:00', 'close': '21:00', 'isOpen': True},
                'tuesday': {'open': '09:00', 'close': '21:00', 'isOpen': True},
                'wednesday': {'open': '09:00', 'close': '21:00', 'isOpen': True},
                'thursday': {'open': '09:00', 'close': '21:00', 'isOpen': True},
                'friday': {'open': '09:00', 'close': '21:00', 'isOpen': True},
                'saturday': {'open': '09:00', 'close': '21:00', 'isOpen': True},
                'sunday': {'open': '09:00', 'close': '21:00', 'isOpen': False},
            }),
            'deliverySettings': {
                'offersDelivery': True,
                'deliveryFee': 3.0,
                'deliveryRadius': 10,  # km
            },
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat(),
        }
        
        # Create cooker document
        cooker_ref = db.collection('cookers').document(user_id)
        cooker_ref.set(chef_data)
        
        # Update user role
        user_ref.update({
            'role': 'chef',
            'cookerId': user_id,
            'updatedAt': datetime.utcnow().isoformat(),
        })
        
        return jsonify({
            'success': True,
            'message': 'تم التسجيل كطباخ بنجاح',
            'chef': chef_data
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cooker_bp.route('/profile', methods=['GET'])
def get_chef_profile():
    """Get chef profile"""
    try:
        user_id = request.args.get('userId')
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        cooker_ref = db.collection('cookers').document(user_id)
        cooker_doc = cooker_ref.get()
        
        if not cooker_doc.exists:
            return jsonify({'error': 'Chef profile not found'}), 404
        
        return jsonify({
            'success': True,
            'chef': cooker_doc.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cooker_bp.route('/profile', methods=['PUT'])
def update_chef_profile():
    """Update chef profile"""
    try:
        data = request.json
        user_id = data.get('userId')
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        cooker_ref = db.collection('cookers').document(user_id)
        cooker_doc = cooker_ref.get()
        
        if not cooker_doc.exists:
            return jsonify({'error': 'Chef profile not found'}), 404
        
        # Fields that can be updated
        update_fields = {}
        allowed_fields = ['name', 'bio', 'phone', 'specialties', 'location', 
                         'address', 'profileImage', 'workingHours', 'deliverySettings']
        
        for field in allowed_fields:
            if field in data:
                update_fields[field] = data[field]
        
        update_fields['updatedAt'] = datetime.utcnow().isoformat()
        
        cooker_ref.update(update_fields)
        
        return jsonify({
            'success': True,
            'message': 'تم تحديث الملف الشخصي'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cooker_bp.route('/availability', methods=['PUT'])
def toggle_availability():
    """Toggle chef availability (online/offline)"""
    try:
        data = request.json
        user_id = data.get('userId')
        is_active = data.get('isActive', True)
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        cooker_ref = db.collection('cookers').document(user_id)
        cooker_ref.update({
            'isActive': is_active,
            'updatedAt': datetime.utcnow().isoformat()
        })
        
        status = 'متاح' if is_active else 'غير متاح'
        return jsonify({
            'success': True,
            'message': f'أنت الآن {status}',
            'isActive': is_active
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cooker_bp.route('/stats', methods=['GET'])
def get_chef_stats():
    """Get chef statistics and dashboard data"""
    try:
        user_id = request.args.get('userId')
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        # Get chef profile
        cooker_ref = db.collection('cookers').document(user_id)
        cooker_doc = cooker_ref.get()
        
        if not cooker_doc.exists:
            return jsonify({'error': 'Chef profile not found'}), 404
        
        chef_data = cooker_doc.to_dict()
        
        # Get orders for this chef
        orders_ref = db.collection('orders').where('chefId', '==', user_id)
        orders = list(orders_ref.stream())
        
        # Calculate stats
        today = datetime.utcnow().date().isoformat()
        today_orders = 0
        today_earnings = 0.0
        pending_orders = 0
        preparing_orders = 0
        
        for order in orders:
            order_data = order.to_dict()
            order_date = order_data.get('createdAt', '')[:10]
            
            if order_date == today:
                today_orders += 1
                if order_data.get('status') == 'completed':
                    today_earnings += order_data.get('total', 0)
            
            if order_data.get('chefStatus') == 'pending':
                pending_orders += 1
            elif order_data.get('chefStatus') == 'preparing':
                preparing_orders += 1
        
        # Get dishes count
        dishes_ref = db.collection('dishes').where('cookerId', '==', user_id)
        dishes_count = len(list(dishes_ref.stream()))
        
        # Get reviews
        reviews_ref = db.collection('reviews').where('cookerId', '==', user_id)
        reviews = list(reviews_ref.stream())
        avg_rating = 0.0
        if reviews:
            total_rating = sum(r.to_dict().get('rating', 0) for r in reviews)
            avg_rating = total_rating / len(reviews)
        
        stats = {
            'todayOrders': today_orders,
            'todayEarnings': today_earnings,
            'pendingOrders': pending_orders,
            'preparingOrders': preparing_orders,
            'totalOrders': chef_data.get('totalOrders', len(orders)),
            'totalEarnings': chef_data.get('totalEarnings', 0),
            'dishesCount': dishes_count,
            'averageRating': round(avg_rating, 1),
            'reviewsCount': len(reviews),
            'isActive': chef_data.get('isActive', False),
        }
        
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============== CHEF'S DISHES ==============

@cooker_bp.route('/dishes', methods=['GET'])
def get_chef_dishes():
    """Get all dishes for a chef"""
    try:
        user_id = request.args.get('userId')
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        dishes_ref = db.collection('dishes').where('cookerId', '==', user_id)
        dishes = []
        
        for doc in dishes_ref.stream():
            dish = doc.to_dict()
            dish['id'] = doc.id
            dishes.append(dish)
        
        # Sort by createdAt descending (handle Firestore timestamps)
        def get_sort_key(x):
            created = x.get('createdAt')
            if created is None:
                return 0
            if hasattr(created, 'timestamp'):
                return created.timestamp()
            return 0
        dishes.sort(key=get_sort_key, reverse=True)
        
        return jsonify({
            'success': True,
            'dishes': dishes,
            'count': len(dishes)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============== CHEF'S ORDERS ==============

@cooker_bp.route('/orders', methods=['GET'])
def get_chef_orders():
    """Get orders for a chef with filtering"""
    try:
        user_id = request.args.get('userId')
        status = request.args.get('status')  # pending, accepted, preparing, ready, completed, cancelled
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('perPage', 20))
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        # Query orders for this chef
        orders_ref = db.collection('orders').where('chefId', '==', user_id)
        
        if status:
            orders_ref = orders_ref.where('chefStatus', '==', status)
        
        orders = []
        for doc in orders_ref.stream():
            order = doc.to_dict()
            order['id'] = doc.id
            orders.append(order)
        
        # Sort by createdAt descending (handle Firestore timestamps)
        def get_order_sort_key(x):
            created = x.get('createdAt')
            if created is None:
                return 0
            if hasattr(created, 'timestamp'):
                return created.timestamp()
            return 0
        orders.sort(key=get_order_sort_key, reverse=True)
        
        # Paginate
        start = (page - 1) * per_page
        end = start + per_page
        paginated_orders = orders[start:end]
        
        return jsonify({
            'success': True,
            'orders': paginated_orders,
            'total': len(orders),
            'page': page,
            'perPage': per_page
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cooker_bp.route('/orders/<order_id>/respond', methods=['PUT'])
def respond_to_order(order_id):
    """Accept or reject an order"""
    try:
        data = request.json
        user_id = data.get('userId')
        action = data.get('action')  # 'accept' or 'reject'
        reason = data.get('reason', '')
        
        if not user_id or not action:
            return jsonify({'error': 'userId and action are required'}), 400
        
        if action not in ['accept', 'reject']:
            return jsonify({'error': 'action must be accept or reject'}), 400
        
        order_ref = db.collection('orders').document(order_id)
        order_doc = order_ref.get()
        
        if not order_doc.exists:
            return jsonify({'error': 'Order not found'}), 404
        
        order_data = order_doc.to_dict()
        
        if order_data.get('chefId') != user_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        if action == 'accept':
            order_ref.update({
                'chefStatus': 'accepted',
                'status': 'confirmed',
                'acceptedAt': datetime.utcnow().isoformat(),
                'updatedAt': datetime.utcnow().isoformat()
            })
            message = 'تم قبول الطلب'
        else:
            order_ref.update({
                'chefStatus': 'rejected',
                'status': 'cancelled',
                'rejectionReason': reason,
                'rejectedAt': datetime.utcnow().isoformat(),
                'updatedAt': datetime.utcnow().isoformat()
            })
            message = 'تم رفض الطلب'
        
        return jsonify({
            'success': True,
            'message': message
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cooker_bp.route('/orders/<order_id>/status', methods=['PUT'])
def update_order_status(order_id):
    """Update order status (preparing, ready, completed)"""
    try:
        data = request.json
        user_id = data.get('userId')
        new_status = data.get('status')
        
        if not user_id or not new_status:
            return jsonify({'error': 'userId and status are required'}), 400
        
        valid_statuses = ['preparing', 'ready', 'out_for_delivery', 'completed']
        if new_status not in valid_statuses:
            return jsonify({'error': f'status must be one of: {valid_statuses}'}), 400
        
        order_ref = db.collection('orders').document(order_id)
        order_doc = order_ref.get()
        
        if not order_doc.exists:
            return jsonify({'error': 'Order not found'}), 404
        
        order_data = order_doc.to_dict()
        
        if order_data.get('chefId') != user_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        update_data = {
            'chefStatus': new_status,
            'updatedAt': datetime.utcnow().isoformat()
        }
        
        # Map chef status to order status
        status_mapping = {
            'preparing': 'preparing',
            'ready': 'ready',
            'out_for_delivery': 'out_for_delivery',
            'completed': 'delivered'
        }
        update_data['status'] = status_mapping.get(new_status, new_status)
        
        # Add timestamp for status
        if new_status == 'preparing':
            update_data['preparingAt'] = datetime.utcnow().isoformat()
        elif new_status == 'ready':
            update_data['readyAt'] = datetime.utcnow().isoformat()
        elif new_status == 'completed':
            update_data['completedAt'] = datetime.utcnow().isoformat()
            # Update chef earnings
            cooker_ref = db.collection('cookers').document(user_id)
            cooker_doc = cooker_ref.get()
            if cooker_doc.exists:
                current_earnings = cooker_doc.to_dict().get('totalEarnings', 0)
                current_orders = cooker_doc.to_dict().get('totalOrders', 0)
                cooker_ref.update({
                    'totalEarnings': current_earnings + order_data.get('subtotal', 0),
                    'totalOrders': current_orders + 1
                })
        
        order_ref.update(update_data)
        
        status_messages = {
            'preparing': 'جاري تحضير الطلب',
            'ready': 'الطلب جاهز',
            'out_for_delivery': 'الطلب في الطريق',
            'completed': 'تم إكمال الطلب'
        }
        
        return jsonify({
            'success': True,
            'message': status_messages.get(new_status, 'تم تحديث الحالة')
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

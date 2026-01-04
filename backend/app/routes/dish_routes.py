"""
Dish routes for Diari app
Handles dish CRUD operations for chefs
"""
from flask import Blueprint, request, jsonify
from firebase_admin import firestore
from datetime import datetime
from functools import lru_cache
from time import time

dish_bp = Blueprint('dish', __name__)
db = firestore.client()

# Simple cache for active cookers (TTL: 5 minutes)
_cooker_cache = {'data': None, 'timestamp': 0}
CACHE_TTL = 300  # 5 minutes


def get_active_cookers():
    """Get active cookers with caching"""
    current_time = time()
    
    # Check if cache is valid
    if _cooker_cache['data'] and (current_time - _cooker_cache['timestamp']) < CACHE_TTL:
        return _cooker_cache['data']
    
    # Fetch from database
    active_cookers = {}
    for cooker_doc in db.collection('cookers').stream():
        cooker_data = cooker_doc.to_dict()
        if cooker_data.get('isActive', True):
            active_cookers[cooker_doc.id] = cooker_data
    
    # Update cache
    _cooker_cache['data'] = active_cookers
    _cooker_cache['timestamp'] = current_time
    
    return active_cookers


# ============== GET ALL DISHES (Public) ==============

@dish_bp.route('/', methods=['GET'])
def get_all_dishes():
    """Get all available dishes (for customers)"""
    try:
        category = request.args.get('category')
        cooker_id = request.args.get('cookerId')
        search = request.args.get('search', '').lower()
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('perPage', 20))
        
        # Use cached cookers
        active_cookers = get_active_cookers()
        
        # Base query - only available dishes
        dishes_ref = db.collection('dishes').where('isAvailable', '==', True)
        
        dishes = []
        for doc in dishes_ref.stream():
            dish = doc.to_dict()
            dish['id'] = doc.id
            
            # Check if chef is active using cache
            chef_id = dish.get('cookerId', '')
            if chef_id not in active_cookers:
                continue  # Skip dishes from inactive chefs
            
            # Apply filters
            if category and dish.get('category', '').lower() != category.lower():
                continue
            if cooker_id and dish.get('cookerId') != cooker_id:
                continue
            if search and search not in dish.get('name', '').lower() and search not in dish.get('description', '').lower():
                continue
            
            # Add cooker info from cache
            cooker_data = active_cookers[chef_id]
            dish['cookerName'] = cooker_data.get('name', dish.get('cookerName', ''))
            dish['cookerImage'] = cooker_data.get('profileImage', '')
            dish['cookerRating'] = cooker_data.get('rating', 0)
            
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
        
        # Paginate
        total = len(dishes)
        start = (page - 1) * per_page
        end = start + per_page
        paginated_dishes = dishes[start:end]
        
        return jsonify({
            'success': True,
            'dishes': paginated_dishes,
            'total': total,
            'page': page,
            'perPage': per_page
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@dish_bp.route('/<dish_id>', methods=['GET'])
def get_dish(dish_id):
    """Get a single dish by ID"""
    try:
        dish_ref = db.collection('dishes').document(dish_id)
        dish_doc = dish_ref.get()
        
        if not dish_doc.exists:
            return jsonify({'error': 'Dish not found'}), 404
        
        dish = dish_doc.to_dict()
        dish['id'] = dish_id
        
        # Get cooker info
        cooker_ref = db.collection('cookers').document(dish.get('cookerId', ''))
        cooker_doc = cooker_ref.get()
        if cooker_doc.exists:
            cooker_data = cooker_doc.to_dict()
            dish['cookerName'] = cooker_data.get('name', '')
            dish['cookerImage'] = cooker_data.get('profileImage', '')
            dish['cookerRating'] = cooker_data.get('rating', 0)
            dish['cookerIsActive'] = cooker_data.get('isActive', False)
        
        return jsonify({
            'success': True,
            'dish': dish
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============== CREATE DISH (Chef only) ==============

@dish_bp.route('/', methods=['POST'])
def create_dish():
    """Create a new dish"""
    try:
        data = request.json
        user_id = data.get('userId')
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        # Verify user is a chef
        cooker_ref = db.collection('cookers').document(user_id)
        cooker_doc = cooker_ref.get()
        
        if not cooker_doc.exists:
            return jsonify({'error': 'You must be a registered chef'}), 403
        
        cooker_data = cooker_doc.to_dict()
        
        # Required fields
        required = ['name', 'price']
        for field in required:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Create dish
        dish_data = {
            'name': data.get('name'),
            'description': data.get('description', ''),
            'price': float(data.get('price', 0)),
            'category': data.get('category', 'عام'),
            'image': data.get('image', ''),
            'images': data.get('images', []),
            'ingredients': data.get('ingredients', []),
            'preparationTime': data.get('preparationTime', 30),  # minutes
            'servingSize': data.get('servingSize', '1 شخص'),
            'isAvailable': True,
            'isSpicy': data.get('isSpicy', False),
            'isVegetarian': data.get('isVegetarian', False),
            'cookerId': user_id,
            'cookerName': cooker_data.get('name', ''),
            'rating': 0.0,
            'reviewsCount': 0,
            'ordersCount': 0,
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat(),
        }
        
        # Add to Firestore
        doc_ref = db.collection('dishes').add(dish_data)
        dish_id = doc_ref[1].id
        dish_data['id'] = dish_id
        
        return jsonify({
            'success': True,
            'message': 'تمت إضافة الطبق بنجاح',
            'dish': dish_data
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============== UPDATE DISH (Chef only) ==============

@dish_bp.route('/<dish_id>', methods=['PUT'])
def update_dish(dish_id):
    """Update a dish"""
    try:
        data = request.json
        user_id = data.get('userId')
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        dish_ref = db.collection('dishes').document(dish_id)
        dish_doc = dish_ref.get()
        
        if not dish_doc.exists:
            return jsonify({'error': 'Dish not found'}), 404
        
        dish_data = dish_doc.to_dict()
        
        # Verify ownership
        if dish_data.get('cookerId') != user_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Fields that can be updated
        update_fields = {}
        allowed_fields = ['name', 'description', 'price', 'category', 'image', 
                         'images', 'ingredients', 'preparationTime', 'servingSize',
                         'isSpicy', 'isVegetarian']
        
        for field in allowed_fields:
            if field in data:
                update_fields[field] = data[field]
        
        # Ensure price is float
        if 'price' in update_fields:
            update_fields['price'] = float(update_fields['price'])
        
        update_fields['updatedAt'] = datetime.utcnow().isoformat()
        
        dish_ref.update(update_fields)
        
        return jsonify({
            'success': True,
            'message': 'تم تحديث الطبق'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============== DELETE DISH (Chef only) ==============

@dish_bp.route('/<dish_id>', methods=['DELETE'])
def delete_dish(dish_id):
    """Delete a dish"""
    try:
        user_id = request.args.get('userId')
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        dish_ref = db.collection('dishes').document(dish_id)
        dish_doc = dish_ref.get()
        
        if not dish_doc.exists:
            return jsonify({'error': 'Dish not found'}), 404
        
        dish_data = dish_doc.to_dict()
        
        # Verify ownership
        if dish_data.get('cookerId') != user_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Delete the dish
        dish_ref.delete()
        
        return jsonify({
            'success': True,
            'message': 'تم حذف الطبق'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============== TOGGLE DISH AVAILABILITY (Chef only) ==============

@dish_bp.route('/<dish_id>/availability', methods=['PUT'])
def toggle_dish_availability(dish_id):
    """Toggle dish availability"""
    try:
        data = request.json
        user_id = data.get('userId')
        is_available = data.get('isAvailable', True)
        
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400
        
        dish_ref = db.collection('dishes').document(dish_id)
        dish_doc = dish_ref.get()
        
        if not dish_doc.exists:
            return jsonify({'error': 'Dish not found'}), 404
        
        dish_data = dish_doc.to_dict()
        
        # Verify ownership
        if dish_data.get('cookerId') != user_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        dish_ref.update({
            'isAvailable': is_available,
            'updatedAt': datetime.utcnow().isoformat()
        })
        
        status = 'متاح' if is_available else 'غير متاح'
        return jsonify({
            'success': True,
            'message': f'الطبق الآن {status}',
            'isAvailable': is_available
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============== GET POPULAR DISHES ==============

@dish_bp.route('/popular', methods=['GET'])
def get_popular_dishes():
    """Get popular dishes based on orders count"""
    try:
        limit = int(request.args.get('limit', 10))
        
        # Use cached cookers
        active_cookers = get_active_cookers()
        
        dishes_ref = db.collection('dishes').where('isAvailable', '==', True)
        
        dishes = []
        for doc in dishes_ref.stream():
            dish = doc.to_dict()
            dish['id'] = doc.id
            
            # Check if chef is active using cache
            chef_id = dish.get('cookerId', '')
            if chef_id not in active_cookers:
                continue
                
            cooker_data = active_cookers[chef_id]
            dish['cookerName'] = cooker_data.get('name', dish.get('cookerName', ''))
            dishes.append(dish)
        
        # Sort by ordersCount descending (or popularity)
        dishes.sort(key=lambda x: x.get('ordersCount', x.get('isPopular', 0)), reverse=True)
        
        return jsonify({
            'success': True,
            'dishes': dishes[:limit]
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============== GET CATEGORIES ==============

@dish_bp.route('/categories', methods=['GET'])
def get_categories():
    """Get all dish categories"""
    try:
        categories = [
            {'id': 'seafood', 'name': 'بحري', 'icon': '🦐'},
            {'id': 'couscous', 'name': 'كسكسي', 'icon': '🍲'},
            {'id': 'pasta', 'name': 'مقرونة', 'icon': '🍝'},
            {'id': 'traditional', 'name': 'تقليدي', 'icon': '🥘'},
            {'id': 'grilled', 'name': 'مشوي', 'icon': '🍖'},
            {'id': 'salads', 'name': 'سلطات', 'icon': '🥗'},
            {'id': 'desserts', 'name': 'حلويات', 'icon': '🍰'},
            {'id': 'drinks', 'name': 'مشروبات', 'icon': '🥤'},
        ]
        
        return jsonify({
            'success': True,
            'categories': categories
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============== SEARCH DISHES ==============

@dish_bp.route('/search', methods=['GET'])
def search_dishes():
    """Search dishes by name, description, or category"""
    try:
        query = request.args.get('q', '').lower().strip()
        category = request.args.get('category', '').lower()
        min_price = float(request.args.get('minPrice', 0))
        max_price = float(request.args.get('maxPrice', 999999))
        limit = int(request.args.get('limit', 20))
        
        if not query and not category:
            return jsonify({
                'success': True,
                'dishes': [],
                'message': 'Please provide a search query or category'
            }), 200
        
        # Use cached cookers
        active_cookers = get_active_cookers()
        
        # Get all available dishes
        dishes_ref = db.collection('dishes').where('isAvailable', '==', True)
        
        results = []
        for doc in dishes_ref.stream():
            dish = doc.to_dict()
            dish['id'] = doc.id
            
            # Check if chef is active
            chef_id = dish.get('cookerId', '')
            if chef_id not in active_cookers:
                continue
            
            # Apply search filter
            name = dish.get('name', '').lower()
            description = dish.get('description', '').lower()
            dish_category = dish.get('category', '').lower()
            price = dish.get('price', 0)
            
            # Match query
            if query and query not in name and query not in description:
                continue
            
            # Match category
            if category and category != dish_category:
                continue
            
            # Match price range
            if price < min_price or price > max_price:
                continue
            
            # Add cooker info
            cooker_data = active_cookers[chef_id]
            dish['cookerName'] = cooker_data.get('name', '')
            
            results.append(dish)
        
        # Sort by relevance (name matches first)
        if query:
            results.sort(key=lambda x: (
                0 if query in x.get('name', '').lower() else 1,
                -x.get('rating', 0)
            ))
        
        return jsonify({
            'success': True,
            'dishes': results[:limit],
            'count': len(results[:limit])
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

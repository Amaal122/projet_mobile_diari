"""
Review Routes
=============
Handle dish and cooker reviews/ratings
"""

from flask import Blueprint, request, jsonify
from firebase_admin import firestore
from datetime import datetime
from app.routes.auth_routes import require_auth

review_bp = Blueprint('reviews', __name__)
db = firestore.client()


@review_bp.route('/', methods=['POST'])
def create_review():
    """Create a new review (simplified endpoint)"""
    try:
        data = request.get_json()
        dish_id = data.get('dishId')
        order_id = data.get('orderId')
        rating = data.get('rating')
        comment = data.get('comment', '')
        user_id = data.get('userId')
        
        # Get user from auth header if not in body
        if not user_id:
            auth_header = request.headers.get('Authorization', '')
            if auth_header.startswith('Bearer '):
                # Just use the token for now - in production verify properly
                user_id = 'authenticated_user'
        
        if not dish_id or not rating:
            return jsonify({'success': False, 'message': 'Missing dishId or rating'}), 400
        
        if not (1 <= rating <= 5):
            return jsonify({'success': False, 'message': 'Rating must be between 1 and 5'}), 400
        
        # Create review
        review_ref = db.collection('reviews').document()
        review_ref.set({
            'dishId': dish_id,
            'orderId': order_id,
            'userId': user_id,
            'rating': rating,
            'comment': comment,
            'createdAt': firestore.SERVER_TIMESTAMP,
        })
        
        # Update dish rating
        reviews = list(db.collection('reviews').where('dishId', '==', dish_id).stream())
        ratings = [r.to_dict().get('rating', 0) for r in reviews]
        avg_rating = sum(ratings) / len(ratings) if ratings else rating
        
        db.collection('dishes').document(dish_id).update({
            'rating': round(avg_rating, 1),
            'reviewCount': len(ratings)
        })
        
        return jsonify({
            'success': True,
            'message': 'Review created',
            'reviewId': review_ref.id
        }), 201
        
    except Exception as e:
        print(f'Error creating review: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@review_bp.route('/dish/<dish_id>', methods=['POST'])
def add_dish_review(dish_id):
    """Add a review for a dish"""
    try:
        data = request.get_json()
        
        # Get user_id from request body or auth header
        user_id = data.get('userId')
        if not user_id:
            # Try to get from auth header
            from app.routes.auth_routes import get_current_user
            current_user = get_current_user()
            if current_user:
                user_id = current_user['userId']
        
        rating = data.get('rating')  # 1-5
        comment = data.get('comment', '')
        
        if not user_id:
            return jsonify({'success': False, 'message': 'User authentication required'}), 401
            
        if not rating:
            return jsonify({'success': False, 'message': 'Missing rating'}), 400
        
        if not (1 <= rating <= 5):
            return jsonify({'success': False, 'message': 'Rating must be between 1 and 5'}), 400
        
        # Get user info for review display
        user_doc = db.collection('users').document(user_id).get()
        user_name = 'مستخدم'
        user_image = ''
        if user_doc.exists:
            user_data = user_doc.to_dict()
            user_name = user_data.get('name', 'مستخدم')
            user_image = user_data.get('profileImage', '')
        
        # Create review document
        review_ref = db.collection('reviews').document()
        review_data = {
            'dishId': dish_id,
            'userId': user_id,
            'userName': user_name,
            'userImage': user_image,
            'rating': rating,
            'comment': comment,
            'createdAt': firestore.SERVER_TIMESTAMP,
        }
        review_ref.set(review_data)
        
        # Update dish rating (calculate average)
        reviews_query = db.collection('reviews').where('dishId', '==', dish_id).stream()
        ratings = [r.to_dict().get('rating', 0) for r in reviews_query]
        avg_rating = sum(ratings) / len(ratings) if ratings else rating
        review_count = len(ratings)
        
        # Update dish document
        dish_ref = db.collection('dishes').document(dish_id)
        dish_ref.update({
            'rating': round(avg_rating, 1),
            'reviewCount': review_count
        })
        
        return jsonify({
            'success': True,
            'message': 'Review added successfully',
            'data': {
                'reviewId': review_ref.id,
                'newAvgRating': round(avg_rating, 1),
                'reviewCount': review_count
            }
        })
        
    except Exception as e:
        print(f'Error adding review: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@review_bp.route('/dish/<dish_id>', methods=['GET'])
def get_dish_reviews(dish_id):
    """Get all reviews for a dish"""
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 10))
        
        # Query reviews - simplified to avoid needing composite index
        reviews_query = db.collection('reviews')\
            .where('dishId', '==', dish_id)\
            .stream()
        
        # Get all reviews for this dish
        all_reviews = []
        for doc in reviews_query:
            review_data = doc.to_dict()
            review_data['id'] = doc.id
            all_reviews.append(review_data)
        
        # Sort by createdAt in Python (avoiding index requirement)
        all_reviews.sort(key=lambda x: x.get('createdAt') or '', reverse=True)
        
        # Paginate
        start = (page - 1) * per_page
        end = start + per_page
        paginated = all_reviews[start:end]
        
        reviews = []
        for review_data in paginated:
            # Get user info
            user_id = review_data.get('userId', '')
            user_doc = db.collection('users').document(user_id).get() if user_id else None
            user_data = user_doc.to_dict() if user_doc and user_doc.exists else {}
            
            reviews.append({
                'id': review_data.get('id'),
                'rating': review_data.get('rating'),
                'comment': review_data.get('comment'),
                'createdAt': review_data.get('createdAt'),
                'userName': user_data.get('name', 'مستخدم'),
                'userImage': user_data.get('profileImage', ''),
            })
        
        total = len(all_reviews)
        
        return jsonify({
            'success': True,
            'data': {
                'reviews': reviews,
                'page': page,
                'per_page': per_page,
                'total': total,
                'pages': (total + per_page - 1) // per_page if total > 0 else 0
            }
        })
        
    except Exception as e:
        print(f'Error getting reviews: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@review_bp.route('/user/<user_id>/dishes', methods=['GET'])
def get_user_dish_reviews(user_id):
    """Get all reviews by a user for dishes"""
    try:
        reviews_query = db.collection('reviews')\
            .where('userId', '==', user_id)\
            .order_by('createdAt', direction=firestore.Query.DESCENDING)\
            .stream()
        
        reviews = []
        for doc in reviews_query.stream():
            review_data = doc.to_dict()
            
            # Get dish info
            dish_doc = db.collection('dishes').document(review_data['dishId']).get()
            dish_data = dish_doc.to_dict() if dish_doc.exists else {}
            
            reviews.append({
                'id': doc.id,
                'rating': review_data.get('rating'),
                'comment': review_data.get('comment'),
                'createdAt': review_data.get('createdAt'),
                'dishId': review_data.get('dishId'),
                'dishName': dish_data.get('nameAr', ''),
                'dishImage': dish_data.get('image', ''),
            })
        
        return jsonify({
            'success': True,
            'data': {'reviews': reviews}
        })
        
    except Exception as e:
        print(f'Error getting user reviews: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@review_bp.route('/<review_id>', methods=['PUT'])
@require_auth
def update_review(review_id):
    """Update a review (edit rating/comment)"""
    try:
        data = request.get_json()
        uid = request.user.get('uid')
        
        review_ref = db.collection('reviews').document(review_id)
        review_doc = review_ref.get()
        
        if not review_doc.exists:
            return jsonify({'success': False, 'message': 'Review not found'}), 404
        
        review_data = review_doc.to_dict()
        
        # Check ownership
        if review_data.get('userId') != uid:
            return jsonify({'error': 'Unauthorized - not your review'}), 403
        
        # Update fields
        update_data = {}
        if 'rating' in data:
            if not (1 <= data['rating'] <= 5):
                return jsonify({'error': 'Rating must be between 1 and 5'}), 400
            update_data['rating'] = data['rating']
        
        if 'comment' in data:
            update_data['comment'] = data['comment']
        
        if update_data:
            update_data['updatedAt'] = firestore.SERVER_TIMESTAMP
            review_ref.update(update_data)
            
            # Recalculate dish rating if rating changed
            if 'rating' in update_data:
                dish_id = review_data.get('dishId')
                reviews_query = db.collection('reviews').where('dishId', '==', dish_id).stream()
                ratings = [r.to_dict().get('rating', 0) for r in reviews_query]
                avg_rating = sum(ratings) / len(ratings) if ratings else 0
                
                db.collection('dishes').document(dish_id).update({
                    'rating': round(avg_rating, 1),
                })
        
        return jsonify({
            'success': True,
            'message': 'Review updated successfully'
        })
        
    except Exception as e:
        print(f'Error updating review: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@review_bp.route('/<review_id>/report', methods=['POST'])
@require_auth
def report_review(review_id):
    """Report a review for inappropriate content"""
    try:
        data = request.get_json() or {}
        uid = request.user.get('uid')
        reason = data.get('reason', 'Inappropriate content')
        
        review_ref = db.collection('reviews').document(review_id)
        review_doc = review_ref.get()
        
        if not review_doc.exists:
            return jsonify({'success': False, 'message': 'Review not found'}), 404
        
        # Mark as reported
        review_ref.update({
            'isReported': True,
            'reportedBy': uid,
            'reportReason': reason,
            'reportedAt': firestore.SERVER_TIMESTAMP
        })
        
        return jsonify({
            'success': True,
            'message': 'Review reported successfully'
        })
        
    except Exception as e:
        print(f'Error reporting review: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@review_bp.route('/<review_id>', methods=['DELETE'])
@require_auth
def delete_review(review_id):
    """Delete a review"""
    try:
        uid = request.user.get('uid')
        
        review_ref = db.collection('reviews').document(review_id)
        review_doc = review_ref.get()
        
        if not review_doc.exists:
            return jsonify({'success': False, 'message': 'Review not found'}), 404
        
        review_data = review_doc.to_dict()
        
        # Check ownership (or admin)
        if review_data.get('userId') != uid:
            # Check if user is admin
            user_doc = db.collection('users').document(uid).get()
            if not user_doc.exists or not user_doc.to_dict().get('isAdmin', False):
                return jsonify({'error': 'Unauthorized'}), 403
        
        dish_id = review_data.get('dishId')
        
        # Delete review
        review_ref.delete()
        
        # Recalculate dish rating
        reviews_query = db.collection('reviews').where('dishId', '==', dish_id).stream()
        ratings = [r.to_dict().get('rating', 0) for r in reviews_query]
        
        if ratings:
            avg_rating = sum(ratings) / len(ratings)
            review_count = len(ratings)
        else:
            avg_rating = 0
            review_count = 0
        
        # Update dish document
        dish_ref = db.collection('dishes').document(dish_id)
        dish_ref.update({
            'rating': round(avg_rating, 1),
            'reviewCount': review_count
        })
        
        return jsonify({
            'success': True,
            'message': 'Review deleted successfully',
            'data': {
                'newAvgRating': round(avg_rating, 1),
                'reviewCount': review_count
            }
        })
        
    except Exception as e:
        print(f'Error deleting review: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500

"""
Admin Routes
============
Admin panel for managing users, orders, and platform settings
"""

from flask import Blueprint, request, jsonify
from app.routes.auth_routes import require_admin
from app.services.firebase_service import get_db
from datetime import datetime, timedelta

admin_bp = Blueprint('admin', __name__)


@admin_bp.route('/stats', methods=['GET'])
@require_admin
def get_platform_stats():
    """Get platform-wide statistics"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        # Count totals
        users_count = len(db.collection('users').stream())
        chefs_count = len(db.collection('cookers').stream())
        dishes_count = len(db.collection('dishes').stream())
        orders_count = len(db.collection('orders').stream())
        
        # Revenue calculation (last 30 days)
        thirty_days_ago = datetime.now() - timedelta(days=30)
        orders = db.collection('orders').where('status', '==', 'delivered').stream()
        
        total_revenue = 0
        monthly_revenue = 0
        
        for order in orders:
            order_data = order.to_dict()
            amount = order_data.get('total', 0)
            total_revenue += amount
            
            order_time = order_data.get('createdAt')
            if order_time and order_time > thirty_days_ago:
                monthly_revenue += amount
        
        return jsonify({
            'totalUsers': users_count,
            'totalChefs': chefs_count,
            'totalDishes': dishes_count,
            'totalOrders': orders_count,
            'totalRevenue': total_revenue,
            'monthlyRevenue': monthly_revenue
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/users', methods=['GET'])
@require_admin
def list_users():
    """List all users with pagination"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 20))
        
        users_ref = db.collection('users').order_by('createdAt').limit(limit)
        
        users = []
        for user in users_ref.stream():
            user_data = user.to_dict()
            user_data['id'] = user.id
            users.append(user_data)
        
        return jsonify({
            'users': users,
            'page': page,
            'limit': limit
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/users/<user_id>/ban', methods=['POST'])
@require_admin
def ban_user(user_id):
    """Ban a user account"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        data = request.get_json() or {}
        reason = data.get('reason', 'Violation of terms of service')
        
        user_ref = db.collection('users').document(user_id)
        user_ref.update({
            'isBanned': True,
            'bannedReason': reason,
            'bannedAt': datetime.now(),
            'bannedBy': request.user.get('uid')
        })
        
        return jsonify({
            'success': True,
            'message': f'User {user_id} banned successfully'
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/users/<user_id>/unban', methods=['POST'])
@require_admin
def unban_user(user_id):
    """Unban a user account"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        user_ref = db.collection('users').document(user_id)
        user_ref.update({
            'isBanned': False,
            'bannedReason': None,
            'unbannedAt': datetime.now(),
            'unbannedBy': request.user.get('uid')
        })
        
        return jsonify({
            'success': True,
            'message': f'User {user_id} unbanned successfully'
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/chefs', methods=['GET'])
@require_admin
def list_chefs():
    """List all chefs with stats"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        chefs_ref = db.collection('cookers').stream()
        
        chefs = []
        for chef in chefs_ref:
            chef_data = chef.to_dict()
            chef_data['id'] = chef.id
            
            # Count chef's dishes
            dishes_count = len(db.collection('dishes').where('cookerId', '==', chef.id).stream())
            chef_data['dishesCount'] = dishes_count
            
            # Count orders
            orders = db.collection('orders').where('cookerId', '==', chef.id).stream()
            total_orders = 0
            total_revenue = 0
            
            for order in orders:
                total_orders += 1
                order_data = order.to_dict()
                total_revenue += order_data.get('total', 0)
            
            chef_data['ordersCount'] = total_orders
            chef_data['totalRevenue'] = total_revenue
            
            chefs.append(chef_data)
        
        return jsonify({'chefs': chefs})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/chefs/<chef_id>/verify', methods=['POST'])
@require_admin
def verify_chef(chef_id):
    """Verify/approve a chef account"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        chef_ref = db.collection('cookers').document(chef_id)
        chef_ref.update({
            'isVerified': True,
            'verifiedAt': datetime.now(),
            'verifiedBy': request.user.get('uid')
        })
        
        return jsonify({
            'success': True,
            'message': f'Chef {chef_id} verified successfully'
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/orders', methods=['GET'])
@require_admin
def list_all_orders():
    """List all orders with filters"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        status_filter = request.args.get('status')
        limit = int(request.args.get('limit', 50))
        
        orders_ref = db.collection('orders').order_by('createdAt', direction='DESCENDING').limit(limit)
        
        if status_filter:
            orders_ref = orders_ref.where('status', '==', status_filter)
        
        orders = []
        for order in orders_ref.stream():
            order_data = order.to_dict()
            order_data['id'] = order.id
            orders.append(order_data)
        
        return jsonify({'orders': orders})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/reports', methods=['GET'])
@require_admin
def get_reports():
    """Get reported content (reviews, chefs, etc.)"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        reports = []
        
        # Get reported reviews
        reviews = db.collection('reviews').where('isReported', '==', True).stream()
        for review in reviews:
            review_data = review.to_dict()
            review_data['id'] = review.id
            review_data['type'] = 'review'
            reports.append(review_data)
        
        # Get reported chefs
        chefs = db.collection('cookers').where('isReported', '==', True).stream()
        for chef in chefs:
            chef_data = chef.to_dict()
            chef_data['id'] = chef.id
            chef_data['type'] = 'chef'
            reports.append(chef_data)
        
        return jsonify({'reports': reports})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/reports/<report_id>/resolve', methods=['POST'])
@require_admin
def resolve_report(report_id):
    """Resolve a report"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        data = request.get_json() or {}
        report_type = data.get('type', 'review')
        action = data.get('action', 'dismiss')  # dismiss, remove, ban
        
        collection = 'reviews' if report_type == 'review' else 'cookers'
        
        if action == 'remove':
            db.collection(collection).document(report_id).delete()
        else:
            db.collection(collection).document(report_id).update({
                'isReported': False,
                'reportResolved': True,
                'reportAction': action,
                'resolvedAt': datetime.now(),
                'resolvedBy': request.user.get('uid')
            })
        
        return jsonify({
            'success': True,
            'message': f'Report resolved with action: {action}'
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

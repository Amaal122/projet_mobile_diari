"""
Analytics Routes
================
Chef analytics dashboard - earnings, orders, popular dishes
"""

from flask import Blueprint, request, jsonify
from app.routes.auth_routes import require_chef
from app.services.firebase_service import get_db
from datetime import datetime, timedelta
from collections import defaultdict

analytics_bp = Blueprint('analytics', __name__)


@analytics_bp.route('/chef/overview', methods=['GET'])
@require_chef
def get_chef_overview():
    """Get chef's dashboard overview"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        chef_id = request.user.get('uid')
        period = request.args.get('period', '30')  # days
        
        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=int(period))
        
        # Get orders
        orders_ref = db.collection('orders').where('cookerId', '==', chef_id)
        orders = list(orders_ref.stream())
        
        # Calculate stats
        total_orders = len(orders)
        total_revenue = 0
        period_revenue = 0
        period_orders = 0
        status_counts = defaultdict(int)
        
        for order in orders:
            order_data = order.to_dict()
            amount = order_data.get('total', 0)
            total_revenue += amount
            
            status = order_data.get('status', 'unknown')
            status_counts[status] += 1
            
            order_time = order_data.get('createdAt')
            if order_time and order_time >= start_date:
                period_revenue += amount
                period_orders += 1
        
        # Get dishes count
        dishes = db.collection('dishes').where('cookerId', '==', chef_id).stream()
        total_dishes = len(list(dishes))
        
        # Calculate average order value
        avg_order_value = period_revenue / period_orders if period_orders > 0 else 0
        
        return jsonify({
            'totalOrders': total_orders,
            'totalRevenue': total_revenue,
            'periodRevenue': period_revenue,
            'periodOrders': period_orders,
            'totalDishes': total_dishes,
            'avgOrderValue': round(avg_order_value, 2),
            'statusBreakdown': dict(status_counts)
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@analytics_bp.route('/chef/popular-dishes', methods=['GET'])
@require_chef
def get_popular_dishes():
    """Get chef's most popular dishes"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        chef_id = request.user.get('uid')
        limit = int(request.args.get('limit', 10))
        
        # Get all chef's dishes
        dishes_ref = db.collection('dishes').where('cookerId', '==', chef_id).stream()
        
        dish_stats = []
        for dish in dishes_ref:
            dish_data = dish.to_dict()
            dish_id = dish.id
            
            # Count orders containing this dish
            orders = db.collection('orders').where('cookerId', '==', chef_id).stream()
            order_count = 0
            total_quantity = 0
            total_revenue = 0
            
            for order in orders:
                order_data = order.to_dict()
                items = order_data.get('items', [])
                
                for item in items:
                    if item.get('dishId') == dish_id:
                        order_count += 1
                        quantity = item.get('quantity', 1)
                        total_quantity += quantity
                        total_revenue += item.get('price', 0) * quantity
            
            dish_stats.append({
                'dishId': dish_id,
                'dishName': dish_data.get('dishName', 'Unknown'),
                'orderCount': order_count,
                'totalQuantity': total_quantity,
                'totalRevenue': total_revenue,
                'imageUrl': dish_data.get('imageUrl')
            })
        
        # Sort by order count
        dish_stats.sort(key=lambda x: x['orderCount'], reverse=True)
        
        return jsonify({
            'popularDishes': dish_stats[:limit]
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@analytics_bp.route('/chef/revenue-chart', methods=['GET'])
@require_chef
def get_revenue_chart():
    """Get revenue data for chart (daily breakdown)"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        chef_id = request.user.get('uid')
        days = int(request.args.get('days', 30))
        
        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        # Get orders in period
        orders_ref = db.collection('orders').where('cookerId', '==', chef_id)
        orders = list(orders_ref.stream())
        
        # Group by date
        daily_revenue = defaultdict(float)
        daily_orders = defaultdict(int)
        
        for order in orders:
            order_data = order.to_dict()
            order_time = order_data.get('createdAt')
            
            if order_time and order_time >= start_date:
                date_key = order_time.strftime('%Y-%m-%d')
                daily_revenue[date_key] += order_data.get('total', 0)
                daily_orders[date_key] += 1
        
        # Create chart data
        chart_data = []
        current = start_date
        while current <= end_date:
            date_key = current.strftime('%Y-%m-%d')
            chart_data.append({
                'date': date_key,
                'revenue': daily_revenue.get(date_key, 0),
                'orders': daily_orders.get(date_key, 0)
            })
            current += timedelta(days=1)
        
        return jsonify({'chartData': chart_data})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@analytics_bp.route('/chef/customer-insights', methods=['GET'])
@require_chef
def get_customer_insights():
    """Get customer behavior insights"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        chef_id = request.user.get('uid')
        
        # Get orders
        orders_ref = db.collection('orders').where('cookerId', '==', chef_id)
        orders = list(orders_ref.stream())
        
        # Analyze customers
        customer_orders = defaultdict(int)
        customer_spending = defaultdict(float)
        
        for order in orders:
            order_data = order.to_dict()
            customer_id = order_data.get('userId')
            
            if customer_id:
                customer_orders[customer_id] += 1
                customer_spending[customer_id] += order_data.get('total', 0)
        
        # Calculate metrics
        total_customers = len(customer_orders)
        repeat_customers = sum(1 for count in customer_orders.values() if count > 1)
        repeat_rate = (repeat_customers / total_customers * 100) if total_customers > 0 else 0
        
        # Top customers
        top_customers = []
        for customer_id, orders_count in sorted(customer_orders.items(), key=lambda x: x[1], reverse=True)[:10]:
            top_customers.append({
                'customerId': customer_id,
                'ordersCount': orders_count,
                'totalSpent': customer_spending[customer_id]
            })
        
        return jsonify({
            'totalCustomers': total_customers,
            'repeatCustomers': repeat_customers,
            'repeatRate': round(repeat_rate, 1),
            'topCustomers': top_customers
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@analytics_bp.route('/chef/peak-hours', methods=['GET'])
@require_chef
def get_peak_hours():
    """Get peak ordering hours"""
    db = get_db()
    if not db:
        return jsonify({'error': 'Database unavailable'}), 503
    
    try:
        chef_id = request.user.get('uid')
        
        # Get orders
        orders_ref = db.collection('orders').where('cookerId', '==', chef_id)
        orders = list(orders_ref.stream())
        
        # Count by hour
        hourly_orders = defaultdict(int)
        
        for order in orders:
            order_data = order.to_dict()
            order_time = order_data.get('createdAt')
            
            if order_time:
                hour = order_time.hour
                hourly_orders[hour] += 1
        
        # Format data
        peak_hours = []
        for hour in range(24):
            peak_hours.append({
                'hour': hour,
                'orders': hourly_orders.get(hour, 0)
            })
        
        return jsonify({'peakHours': peak_hours})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

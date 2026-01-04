"""
Auto-Notification Service
=========================
Automatically send notifications on order status changes and other events
"""

from firebase_admin import firestore
from app.routes.notification_routes import send_notification
from datetime import datetime

db = firestore.client()


def notify_order_created(order_id, order_data):
    """Notify chef when new order is placed"""
    try:
        cooker_id = order_data.get('cookerId')
        customer_id = order_data.get('userId')
        
        if not cooker_id:
            return
        
        # Get customer name
        customer_doc = db.collection('users').document(customer_id).get()
        customer_name = customer_doc.to_dict().get('name', 'عميل') if customer_doc.exists else 'عميل'
        
        # Send notification to chef
        send_notification(
            user_id=cooker_id,
            title='طلب جديد 🎉',
            body=f'لديك طلب جديد من {customer_name}',
            data={
                'type': 'new_order',
                'orderId': order_id,
                'screen': 'OrderDetails'
            }
        )
        
        print(f"Sent new order notification to chef {cooker_id}")
    
    except Exception as e:
        print(f"Error sending order creation notification: {e}")


def notify_order_accepted(order_id, order_data):
    """Notify customer when chef accepts order"""
    try:
        customer_id = order_data.get('userId')
        cooker_id = order_data.get('cookerId')
        
        if not customer_id:
            return
        
        # Get chef name
        cooker_doc = db.collection('cookers').document(cooker_id).get()
        cooker_name = cooker_doc.to_dict().get('name', 'الطاهي') if cooker_doc.exists else 'الطاهي'
        
        # Send notification
        send_notification(
            user_id=customer_id,
            title='تم قبول الطلب ✅',
            body=f'{cooker_name} قبل طلبك وبدأ في التحضير',
            data={
                'type': 'order_accepted',
                'orderId': order_id,
                'screen': 'OrderDetails'
            }
        )
        
        print(f"Sent order accepted notification to customer {customer_id}")
    
    except Exception as e:
        print(f"Error sending order accepted notification: {e}")


def notify_order_ready(order_id, order_data):
    """Notify customer when food is ready"""
    try:
        customer_id = order_data.get('userId')
        
        if not customer_id:
            return
        
        send_notification(
            user_id=customer_id,
            title='طلبك جاهز! 🍽️',
            body='طلبك جاهز للاستلام أو التوصيل',
            data={
                'type': 'order_ready',
                'orderId': order_id,
                'screen': 'OrderDetails'
            }
        )
        
        print(f"Sent order ready notification to customer {customer_id}")
    
    except Exception as e:
        print(f"Error sending order ready notification: {e}")


def notify_order_out_for_delivery(order_id, order_data):
    """Notify customer when order is out for delivery"""
    try:
        customer_id = order_data.get('userId')
        
        if not customer_id:
            return
        
        send_notification(
            user_id=customer_id,
            title='الطلب في الطريق 🚗',
            body='طلبك في الطريق إليك',
            data={
                'type': 'order_delivery',
                'orderId': order_id,
                'screen': 'OrderTracking'
            }
        )
        
        print(f"Sent delivery notification to customer {customer_id}")
    
    except Exception as e:
        print(f"Error sending delivery notification: {e}")


def notify_order_delivered(order_id, order_data):
    """Notify customer when order is delivered"""
    try:
        customer_id = order_data.get('userId')
        
        if not customer_id:
            return
        
        send_notification(
            user_id=customer_id,
            title='تم التوصيل! 🎉',
            body='تم توصيل طلبك بنجاح. نتمنى أن تستمتع بوجبتك!',
            data={
                'type': 'order_delivered',
                'orderId': order_id,
                'screen': 'OrderDetails'
            }
        )
        
        print(f"Sent delivered notification to customer {customer_id}")
    
    except Exception as e:
        print(f"Error sending delivered notification: {e}")


def notify_order_cancelled(order_id, order_data):
    """Notify both parties when order is cancelled"""
    try:
        customer_id = order_data.get('userId')
        cooker_id = order_data.get('cookerId')
        cancelled_by = order_data.get('cancelledBy', customer_id)
        
        # Notify the other party
        if cancelled_by == customer_id and cooker_id:
            # Customer cancelled, notify chef
            send_notification(
                user_id=cooker_id,
                title='تم إلغاء الطلب',
                body=f'ألغى العميل الطلب #{order_id[:8]}',
                data={
                    'type': 'order_cancelled',
                    'orderId': order_id,
                    'screen': 'OrderDetails'
                }
            )
        elif cancelled_by == cooker_id and customer_id:
            # Chef cancelled, notify customer
            send_notification(
                user_id=customer_id,
                title='تم إلغاء الطلب ❌',
                body='عذراً، ألغى الطاهي طلبك. سيتم إرجاع المبلغ',
                data={
                    'type': 'order_cancelled',
                    'orderId': order_id,
                    'screen': 'OrderDetails'
                }
            )
        
        print(f"Sent cancellation notifications for order {order_id}")
    
    except Exception as e:
        print(f"Error sending cancellation notification: {e}")


def notify_new_review(review_id, review_data):
    """Notify chef when they receive a review"""
    try:
        dish_id = review_data.get('dishId')
        rating = review_data.get('rating')
        
        # Get dish to find chef
        dish_doc = db.collection('dishes').document(dish_id).get()
        if not dish_doc.exists:
            return
        
        dish_data = dish_doc.to_dict()
        cooker_id = dish_data.get('cookerId')
        dish_name = dish_data.get('name', 'طبق')
        
        if not cooker_id:
            return
        
        # Create message based on rating
        if rating >= 4:
            emoji = '⭐' * rating
            message = f'تقييم رائع {emoji} على {dish_name}'
        else:
            message = f'تقييم جديد على {dish_name}'
        
        send_notification(
            user_id=cooker_id,
            title='تقييم جديد',
            body=message,
            data={
                'type': 'new_review',
                'reviewId': review_id,
                'dishId': dish_id,
                'screen': 'DishDetails'
            }
        )
        
        print(f"Sent review notification to chef {cooker_id}")
    
    except Exception as e:
        print(f"Error sending review notification: {e}")


def notify_payment_confirmed(order_id, order_data):
    """Notify chef when payment is confirmed"""
    try:
        cooker_id = order_data.get('cookerId')
        amount = order_data.get('total', 0)
        
        if not cooker_id:
            return
        
        send_notification(
            user_id=cooker_id,
            title='تم استلام الدفعة 💰',
            body=f'تم تأكيد الدفع بمبلغ {amount} ريال',
            data={
                'type': 'payment_confirmed',
                'orderId': order_id,
                'screen': 'OrderDetails'
            }
        )
        
        print(f"Sent payment confirmation to chef {cooker_id}")
    
    except Exception as e:
        print(f"Error sending payment notification: {e}")


# Auto-trigger function to be called from order routes
def handle_order_status_change(order_id, old_status, new_status, order_data):
    """Main function to handle order status changes and trigger appropriate notifications"""
    try:
        status_handlers = {
            'pending': notify_order_created,
            'accepted': notify_order_accepted,
            'ready': notify_order_ready,
            'delivering': notify_order_out_for_delivery,
            'delivered': notify_order_delivered,
            'cancelled': notify_order_cancelled,
        }
        
        handler = status_handlers.get(new_status)
        if handler:
            handler(order_id, order_data)
    
    except Exception as e:
        print(f"Error handling order status change: {e}")

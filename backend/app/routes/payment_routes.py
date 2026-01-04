"""
Payment Routes
==============
Handle payment processing (Stripe/PayPal integration ready)
"""

from flask import Blueprint, request, jsonify
from firebase_admin import firestore
from datetime import datetime
from app.routes.auth_routes import require_auth

payment_bp = Blueprint('payments', __name__)
db = firestore.client()

# Payment gateway configuration (add your keys)
STRIPE_ENABLED = False  # Set to True when you add Stripe keys
PAYPAL_ENABLED = False  # Set to True when you add PayPal keys


@payment_bp.route('/methods', methods=['GET'])
@require_auth
def get_payment_methods():
    """Get available payment methods"""
    try:
        methods = [
            {
                'id': 'cash',
                'name': 'Cash on Delivery',
                'icon': '💵',
                'enabled': True,
                'description': 'Pay when you receive your order'
            }
        ]
        
        if STRIPE_ENABLED:
            methods.append({
                'id': 'card',
                'name': 'Credit/Debit Card',
                'icon': '💳',
                'enabled': True,
                'description': 'Pay securely with Stripe'
            })
        
        if PAYPAL_ENABLED:
            methods.append({
                'id': 'paypal',
                'name': 'PayPal',
                'icon': '🅿️',
                'enabled': True,
                'description': 'Pay with your PayPal account'
            })
        
        return jsonify({
            'success': True,
            'methods': methods
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@payment_bp.route('/intent', methods=['POST'])
@require_auth
def create_payment_intent():
    """Create payment intent (Stripe integration)"""
    try:
        if not STRIPE_ENABLED:
            return jsonify({
                'error': 'Card payments not enabled. Please configure Stripe.'
            }), 503
        
        data = request.get_json()
        amount = data.get('amount')  # Amount in TND
        order_id = data.get('orderId')
        
        if not amount or not order_id:
            return jsonify({'error': 'amount and orderId are required'}), 400
        
        # TODO: Integrate with Stripe
        # import stripe
        # stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
        # 
        # intent = stripe.PaymentIntent.create(
        #     amount=int(amount * 100),  # Stripe uses cents
        #     currency='tnd',
        #     metadata={'order_id': order_id}
        # )
        
        # For now, return a mock response
        return jsonify({
            'success': True,
            'clientSecret': 'mock_payment_intent_secret',
            'message': 'Stripe integration pending'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@payment_bp.route('/confirm', methods=['POST'])
@require_auth
def confirm_payment():
    """Confirm payment and update order status"""
    try:
        data = request.get_json()
        order_id = data.get('orderId')
        payment_method = data.get('paymentMethod')
        payment_id = data.get('paymentId')  # Stripe/PayPal payment ID
        
        if not order_id or not payment_method:
            return jsonify({'error': 'orderId and paymentMethod are required'}), 400
        
        # Verify order exists
        order_ref = db.collection('orders').document(order_id)
        order_doc = order_ref.get()
        
        if not order_doc.exists:
            return jsonify({'error': 'Order not found'}), 404
        
        # Update order with payment info
        order_ref.update({
            'paymentStatus': 'paid' if payment_method != 'cash' else 'pending',
            'paymentMethod': payment_method,
            'paymentId': payment_id,
            'paidAt': firestore.SERVER_TIMESTAMP if payment_method != 'cash' else None,
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        
        # Create payment record
        payment_ref = db.collection('payments').document()
        payment_ref.set({
            'orderId': order_id,
            'userId': request.user.get('uid'),
            'amount': order_doc.to_dict().get('total', 0),
            'currency': 'TND',
            'paymentMethod': payment_method,
            'paymentId': payment_id,
            'status': 'completed' if payment_method != 'cash' else 'pending',
            'createdAt': firestore.SERVER_TIMESTAMP
        })
        
        return jsonify({
            'success': True,
            'message': 'Payment confirmed',
            'paymentStatus': 'paid' if payment_method != 'cash' else 'pending'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@payment_bp.route('/history', methods=['GET'])
@require_auth
def get_payment_history():
    """Get user's payment history"""
    try:
        uid = request.user.get('uid')
        
        payments_ref = db.collection('payments')\
            .where('userId', '==', uid)\
            .stream()
        
        payments = []
        for doc in payments_ref:
            payment = doc.to_dict()
            payment['id'] = doc.id
            
            # Convert timestamp
            if payment.get('createdAt'):
                payment['createdAt'] = payment['createdAt'].isoformat() if hasattr(payment['createdAt'], 'isoformat') else str(payment['createdAt'])
            
            payments.append(payment)
        
        # Sort by date
        payments.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
        
        return jsonify({
            'success': True,
            'payments': payments
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@payment_bp.route('/refund', methods=['POST'])
@require_auth
def request_refund():
    """Request a refund for an order"""
    try:
        data = request.get_json()
        order_id = data.get('orderId')
        reason = data.get('reason', '')
        
        if not order_id:
            return jsonify({'error': 'orderId is required'}), 400
        
        uid = request.user.get('uid')
        
        # Verify order belongs to user
        order_ref = db.collection('orders').document(order_id)
        order_doc = order_ref.get()
        
        if not order_doc.exists:
            return jsonify({'error': 'Order not found'}), 404
        
        order_data = order_doc.to_dict()
        
        if order_data.get('userId') != uid:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Check if order is eligible for refund
        if order_data.get('status') in ['delivered', 'cancelled']:
            return jsonify({'error': 'Order not eligible for refund'}), 400
        
        # Create refund request
        refund_ref = db.collection('refunds').document()
        refund_ref.set({
            'orderId': order_id,
            'userId': uid,
            'amount': order_data.get('total', 0),
            'reason': reason,
            'status': 'pending',  # pending -> approved -> processed
            'createdAt': firestore.SERVER_TIMESTAMP
        })
        
        # Update order status
        order_ref.update({
            'refundRequested': True,
            'refundId': refund_ref.id,
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        
        return jsonify({
            'success': True,
            'message': 'Refund request submitted',
            'refundId': refund_ref.id
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@payment_bp.route('/webhook/stripe', methods=['POST'])
def stripe_webhook():
    """Handle Stripe webhook events"""
    try:
        # TODO: Implement Stripe webhook signature verification
        # import stripe
        # 
        # payload = request.data
        # sig_header = request.headers.get('Stripe-Signature')
        # 
        # event = stripe.Webhook.construct_event(
        #     payload, sig_header, os.getenv('STRIPE_WEBHOOK_SECRET')
        # )
        
        # Handle different event types
        # if event['type'] == 'payment_intent.succeeded':
        #     # Payment successful
        #     pass
        # elif event['type'] == 'payment_intent.payment_failed':
        #     # Payment failed
        #     pass
        
        return jsonify({'success': True}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400

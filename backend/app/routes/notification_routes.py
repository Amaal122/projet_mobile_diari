"""
Notification Routes
===================
Handle push notifications via Firebase Cloud Messaging
"""

from flask import Blueprint, request, jsonify
from firebase_admin import firestore, messaging
from app.routes.auth_routes import require_auth

notification_bp = Blueprint('notifications', __name__)
db = firestore.client()


@notification_bp.route('/register', methods=['POST'])
@require_auth
def register_fcm_token():
    """Register or update FCM token for user"""
    try:
        data = request.get_json()
        fcm_token = data.get('fcmToken')
        uid = request.user.get('uid')
        
        if not fcm_token:
            return jsonify({'error': 'fcmToken is required'}), 400
        
        # Store FCM token in user document
        user_ref = db.collection('users').document(uid)
        user_ref.update({
            'fcmToken': fcm_token,
            'fcmTokenUpdatedAt': firestore.SERVER_TIMESTAMP
        })
        
        return jsonify({
            'success': True,
            'message': 'FCM token registered successfully'
        }), 200
        
    except Exception as e:
        print(f'Error registering FCM token: {e}')
        return jsonify({'error': str(e)}), 500


@notification_bp.route('/settings', methods=['GET'])
@require_auth
def get_notification_settings():
    """Get user notification preferences"""
    try:
        uid = request.user.get('uid')
        
        user_ref = db.collection('users').document(uid)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            return jsonify({'error': 'User not found'}), 404
        
        user_data = user_doc.to_dict()
        
        # Default notification settings
        settings = user_data.get('notificationSettings', {
            'orderUpdates': True,
            'newMessages': True,
            'promotions': True,
            'reviews': True
        })
        
        return jsonify({
            'success': True,
            'settings': settings
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@notification_bp.route('/settings', methods=['PUT'])
@require_auth
def update_notification_settings():
    """Update user notification preferences"""
    try:
        data = request.get_json()
        uid = request.user.get('uid')
        
        settings = {
            'orderUpdates': data.get('orderUpdates', True),
            'newMessages': data.get('newMessages', True),
            'promotions': data.get('promotions', True),
            'reviews': data.get('reviews', True)
        }
        
        user_ref = db.collection('users').document(uid)
        user_ref.update({
            'notificationSettings': settings
        })
        
        return jsonify({
            'success': True,
            'message': 'Notification settings updated'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def send_notification(user_id, title, body, data=None):
    """
    Helper function to send push notification to a user
    
    Args:
        user_id: Firebase user ID
        title: Notification title
        body: Notification body text
        data: Optional dict of custom data
    """
    try:
        # Get user's FCM token
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            print(f'User {user_id} not found')
            return False
        
        user_data = user_doc.to_dict()
        fcm_token = user_data.get('fcmToken')
        
        if not fcm_token:
            print(f'No FCM token for user {user_id}')
            return False
        
        # Check notification preferences
        settings = user_data.get('notificationSettings', {})
        notification_type = data.get('type') if data else None
        
        if notification_type == 'order' and not settings.get('orderUpdates', True):
            return False
        if notification_type == 'message' and not settings.get('newMessages', True):
            return False
        if notification_type == 'review' and not settings.get('reviews', True):
            return False
        
        # Build notification message
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            data=data or {},
            token=fcm_token
        )
        
        # Send notification
        response = messaging.send(message)
        print(f'Successfully sent notification to {user_id}: {response}')
        return True
        
    except Exception as e:
        print(f'Error sending notification: {e}')
        return False


@notification_bp.route('/test', methods=['POST'])
@require_auth
def send_test_notification():
    """Send a test notification (for debugging)"""
    try:
        uid = request.user.get('uid')
        data = request.get_json()
        
        title = data.get('title', 'Test Notification')
        body = data.get('body', 'This is a test notification from Diari')
        
        success = send_notification(uid, title, body, {'type': 'test'})
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Test notification sent'
            }), 200
        else:
            return jsonify({
                'success': False,
                'message': 'Failed to send notification. Check FCM token.'
            }), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

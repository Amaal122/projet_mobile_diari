"""
Message Routes
==============
Handle messaging between users and cookers
"""

from flask import Blueprint, request, jsonify
from firebase_admin import firestore
from datetime import datetime

message_bp = Blueprint('messages', __name__)
db = firestore.client()


@message_bp.route('/', methods=['POST'])
def send_direct_message():
    """Send a direct message to another user (creates conversation if needed)"""
    try:
        data = request.get_json()
        sender_id = request.headers.get('Authorization', '').replace('Bearer ', '')[:36] if 'Authorization' in request.headers else None
        receiver_id = data.get('receiverId')
        content = data.get('content', data.get('text', ''))
        
        # Get sender from token (use userId from data as fallback)
        if not sender_id or len(sender_id) < 20:
            sender_id = data.get('senderId', data.get('userId'))
        
        if not receiver_id or not content:
            return jsonify({'success': False, 'message': 'Missing receiverId or content'}), 400
        
        # Find or create conversation
        existing = db.collection('conversations')\
            .where('participants', 'array_contains', sender_id)\
            .stream()
        
        conversation_id = None
        for doc in existing:
            conv_data = doc.to_dict()
            if receiver_id in conv_data.get('participants', []):
                conversation_id = doc.id
                break
        
        if not conversation_id:
            # Create new conversation
            conv_ref = db.collection('conversations').document()
            conv_ref.set({
                'participants': [sender_id, receiver_id],
                'lastMessage': content[:50],
                'lastMessageTime': firestore.SERVER_TIMESTAMP,
                f'unreadCount_{sender_id}': 0,
                f'unreadCount_{receiver_id}': 1,
                'createdAt': firestore.SERVER_TIMESTAMP,
            })
            conversation_id = conv_ref.id
        else:
            # Update existing conversation
            db.collection('conversations').document(conversation_id).update({
                'lastMessage': content[:50],
                'lastMessageTime': firestore.SERVER_TIMESTAMP,
                f'unreadCount_{receiver_id}': firestore.Increment(1),
            })
        
        # Add message to conversation
        msg_ref = db.collection('conversations').document(conversation_id)\
            .collection('messages').document()
        msg_ref.set({
            'senderId': sender_id,
            'text': content,
            'timestamp': firestore.SERVER_TIMESTAMP,
            'read': False,
        })
        
        return jsonify({
            'success': True,
            'message': 'Message sent',
            'data': {'messageId': msg_ref.id, 'conversationId': conversation_id}
        })
        
    except Exception as e:
        print(f'Error sending message: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@message_bp.route('/conversations', methods=['GET'])
def get_conversations():
    """Get all conversations for current user"""
    try:
        user_id = request.args.get('userId')
        if not user_id:
            return jsonify({'success': False, 'message': 'Missing userId'}), 400
        
        # Get conversations where user is participant - simplified query to avoid composite index
        conversations_query = db.collection('conversations')\
            .where('participants', 'array_contains', user_id)\
            .stream()
        
        # Get all conversations and sort in Python
        all_convs = []
        for doc in conversations_query:
            conv_data = doc.to_dict()
            conv_data['id'] = doc.id
            all_convs.append(conv_data)
        
        # Sort by lastMessageTime in Python
        all_convs.sort(key=lambda x: x.get('lastMessageTime') or '', reverse=True)
        
        conversations = []
        for conv_data in all_convs:
            # Get other participant info
            other_user_id = [p for p in conv_data.get('participants', []) if p != user_id][0] if len(conv_data.get('participants', [])) > 1 else None
            
            if other_user_id:
                user_doc = db.collection('users').document(other_user_id).get()
                user_data = user_doc.to_dict() if user_doc.exists else {}
                
                conversations.append({
                    'id': conv_data.get('id'),
                    'otherUserId': other_user_id,
                    'otherUserName': user_data.get('name', 'مستخدم'),
                    'otherUserImage': user_data.get('profileImage', ''),
                    'lastMessage': conv_data.get('lastMessage', ''),
                    'lastMessageTime': conv_data.get('lastMessageTime'),
                    'unreadCount': conv_data.get(f'unreadCount_{user_id}', 0),
                })
        
        return jsonify({
            'success': True,
            'data': {'conversations': conversations}
        })
        
    except Exception as e:
        print(f'Error getting conversations: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@message_bp.route('/conversations/<conversation_id>/messages', methods=['GET'])
def get_messages(conversation_id):
    """Get messages in a conversation"""
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 50))
        
        # Get messages
        messages_query = db.collection('conversations').document(conversation_id)\
            .collection('messages')\
            .order_by('timestamp', direction=firestore.Query.DESCENDING)\
            .limit(per_page)\
            .offset((page - 1) * per_page)
        
        messages = []
        for doc in messages_query.stream():
            msg_data = doc.to_dict()
            messages.append({
                'id': doc.id,
                'senderId': msg_data.get('senderId'),
                'text': msg_data.get('text'),
                'timestamp': msg_data.get('timestamp'),
                'read': msg_data.get('read', False),
            })
        
        # Reverse to get chronological order
        messages.reverse()
        
        return jsonify({
            'success': True,
            'data': {'messages': messages}
        })
        
    except Exception as e:
        print(f'Error getting messages: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@message_bp.route('/conversations/<conversation_id>/messages', methods=['POST'])
def send_message(conversation_id):
    """Send a message in a conversation"""
    try:
        data = request.get_json()
        sender_id = data.get('senderId')
        text = data.get('text')
        
        if not sender_id or not text:
            return jsonify({'success': False, 'message': 'Missing senderId or text'}), 400
        
        # Create message
        message_ref = db.collection('conversations').document(conversation_id)\
            .collection('messages').document()
        
        message_data = {
            'senderId': sender_id,
            'text': text,
            'timestamp': firestore.SERVER_TIMESTAMP,
            'read': False,
        }
        message_ref.set(message_data)
        
        # Update conversation last message
        conv_ref = db.collection('conversations').document(conversation_id)
        conv_doc = conv_ref.get()
        
        if conv_doc.exists:
            conv_data = conv_doc.to_dict()
            participants = conv_data.get('participants', [])
            
            # Increment unread count for other participants
            updates = {
                'lastMessage': text[:50] + ('...' if len(text) > 50 else ''),
                'lastMessageTime': firestore.SERVER_TIMESTAMP,
            }
            
            for participant in participants:
                if participant != sender_id:
                    updates[f'unreadCount_{participant}'] = firestore.Increment(1)
            
            conv_ref.update(updates)
        
        return jsonify({
            'success': True,
            'message': 'Message sent',
            'data': {'messageId': message_ref.id}
        })
        
    except Exception as e:
        print(f'Error sending message: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@message_bp.route('/conversations', methods=['POST'])
def create_conversation():
    """Create a new conversation between users"""
    try:
        data = request.get_json()
        user_id1 = data.get('userId1')
        user_id2 = data.get('userId2')
        
        if not user_id1 or not user_id2:
            return jsonify({'success': False, 'message': 'Missing userId1 or userId2'}), 400
        
        # Check if conversation already exists
        existing = db.collection('conversations')\
            .where('participants', 'array_contains', user_id1)\
            .stream()
        
        for doc in existing:
            conv_data = doc.to_dict()
            if user_id2 in conv_data.get('participants', []):
                return jsonify({
                    'success': True,
                    'data': {'conversationId': doc.id, 'existed': True}
                })
        
        # Create new conversation
        conv_ref = db.collection('conversations').document()
        conv_data = {
            'participants': [user_id1, user_id2],
            'lastMessage': '',
            'lastMessageTime': firestore.SERVER_TIMESTAMP,
            f'unreadCount_{user_id1}': 0,
            f'unreadCount_{user_id2}': 0,
            'createdAt': firestore.SERVER_TIMESTAMP,
        }
        conv_ref.set(conv_data)
        
        return jsonify({
            'success': True,
            'data': {'conversationId': conv_ref.id, 'existed': False}
        })
        
    except Exception as e:
        print(f'Error creating conversation: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500


@message_bp.route('/conversations/<conversation_id>/mark-read', methods=['POST'])
def mark_messages_read(conversation_id):
    """Mark all messages in a conversation as read for a user"""
    try:
        data = request.get_json()
        user_id = data.get('userId')
        
        if not user_id:
            return jsonify({'success': False, 'message': 'Missing userId'}), 400
        
        # Update conversation unread count
        conv_ref = db.collection('conversations').document(conversation_id)
        conv_ref.update({
            f'unreadCount_{user_id}': 0
        })
        
        # Mark all messages as read
        messages_query = db.collection('conversations').document(conversation_id)\
            .collection('messages')\
            .where('read', '==', False)\
            .stream()
        
        batch = db.batch()
        for doc in messages_query:
            batch.update(doc.reference, {'read': True})
        batch.commit()
        
        return jsonify({
            'success': True,
            'message': 'Messages marked as read'
        })
        
    except Exception as e:
        print(f'Error marking messages read: {e}')
        return jsonify({'success': False, 'message': str(e)}), 500

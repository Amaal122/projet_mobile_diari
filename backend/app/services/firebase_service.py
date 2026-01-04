"""
Firebase Admin SDK Service
==========================
Initializes Firebase and provides Firestore access
"""

import os
import firebase_admin
from firebase_admin import credentials, firestore, auth

# Global Firestore client
db = None

def init_firebase():
    """Initialize Firebase Admin SDK"""
    global db
    
    cred_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH', 'serviceAccountKey.json')
    
    if not firebase_admin._apps:
        try:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            db = firestore.client()
            print("✅ Firebase initialized successfully")
        except Exception as e:
            print(f"⚠️ Firebase initialization failed: {e}")
            print("   Running without Firebase - some features disabled")
            db = None
    else:
        db = firestore.client()
    
    return db


def get_db():
    """Get Firestore database instance"""
    global db
    if db is None:
        db = firestore.client()
    return db


def verify_token(id_token: str):
    """
    Verify Firebase ID token from Flutter app
    Returns decoded token with user info or None
    """
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception as e:
        print(f"Token verification failed: {e}")
        return None


def get_user_by_uid(uid: str):
    """Get Firebase user by UID"""
    try:
        return auth.get_user(uid)
    except Exception as e:
        print(f"Get user failed: {e}")
        return None

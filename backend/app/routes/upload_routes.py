"""
Image Upload Routes
==================
Handle image uploads to Firebase Storage
"""

from flask import Blueprint, request, jsonify
import firebase_admin
from firebase_admin import storage
from werkzeug.utils import secure_filename
import uuid
import os
from app.routes.auth_routes import require_auth

upload_bp = Blueprint('upload', __name__)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB


def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@upload_bp.route('/image', methods=['POST'])
@require_auth
def upload_image():
    """Upload an image to Firebase Storage"""
    try:
        # Check if file is in request
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': f'File type not allowed. Allowed: {", ".join(ALLOWED_EXTENSIONS)}'}), 400
        
        # Check file size
        file.seek(0, os.SEEK_END)
        file_size = file.tell()
        file.seek(0)
        
        if file_size > MAX_FILE_SIZE:
            return jsonify({'error': f'File too large. Max size: {MAX_FILE_SIZE // (1024*1024)}MB'}), 400
        
        # Get upload context
        context = request.form.get('context', 'general')  # dish, profile, chef, etc.
        uid = request.user.get('uid')
        
        # Generate unique filename
        ext = file.filename.rsplit('.', 1)[1].lower()
        filename = f"{context}/{uid}/{uuid.uuid4()}.{ext}"
        
        # Upload to Firebase Storage
        bucket = storage.bucket()
        blob = bucket.blob(filename)
        
        # Set content type
        content_type = file.content_type or 'image/jpeg'
        blob.upload_from_file(file, content_type=content_type)
        
        # Make file publicly accessible
        blob.make_public()
        
        # Get public URL
        image_url = blob.public_url
        
        return jsonify({
            'success': True,
            'imageUrl': image_url,
            'filename': filename,
            'size': file_size
        })
    
    except Exception as e:
        print(f'Error uploading image: {e}')
        return jsonify({'error': str(e)}), 500


@upload_bp.route('/image/multiple', methods=['POST'])
@require_auth
def upload_multiple_images():
    """Upload multiple images (e.g., for dish gallery)"""
    try:
        files = request.files.getlist('files')
        
        if not files:
            return jsonify({'error': 'No files provided'}), 400
        
        if len(files) > 5:
            return jsonify({'error': 'Maximum 5 images allowed'}), 400
        
        context = request.form.get('context', 'general')
        uid = request.user.get('uid')
        
        uploaded_images = []
        bucket = storage.bucket()
        
        for file in files:
            if file.filename == '':
                continue
            
            if not allowed_file(file.filename):
                continue
            
            # Check file size
            file.seek(0, os.SEEK_END)
            file_size = file.tell()
            file.seek(0)
            
            if file_size > MAX_FILE_SIZE:
                continue
            
            # Generate unique filename
            ext = file.filename.rsplit('.', 1)[1].lower()
            filename = f"{context}/{uid}/{uuid.uuid4()}.{ext}"
            
            # Upload
            blob = bucket.blob(filename)
            content_type = file.content_type or 'image/jpeg'
            blob.upload_from_file(file, content_type=content_type)
            blob.make_public()
            
            uploaded_images.append({
                'imageUrl': blob.public_url,
                'filename': filename,
                'size': file_size
            })
        
        return jsonify({
            'success': True,
            'images': uploaded_images,
            'count': len(uploaded_images)
        })
    
    except Exception as e:
        print(f'Error uploading images: {e}')
        return jsonify({'error': str(e)}), 500


@upload_bp.route('/image/delete', methods=['POST'])
@require_auth
def delete_image():
    """Delete an image from Firebase Storage"""
    try:
        data = request.get_json()
        filename = data.get('filename')
        
        if not filename:
            return jsonify({'error': 'Filename required'}), 400
        
        # Security: ensure user can only delete their own files
        uid = request.user.get('uid')
        if uid not in filename:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Delete from storage
        bucket = storage.bucket()
        blob = bucket.blob(filename)
        blob.delete()
        
        return jsonify({
            'success': True,
            'message': 'Image deleted successfully'
        })
    
    except Exception as e:
        print(f'Error deleting image: {e}')
        return jsonify({'error': str(e)}), 500

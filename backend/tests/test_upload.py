"""
Unit Tests for Upload Routes
=============================
Tests image upload endpoints
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os
import io
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from application import create_app


class TestUploadRoutes(unittest.TestCase):
    
    def setUp(self):
        """Set up test client"""
        self.app = create_app()
        self.client = self.app.test_client()
        self.app.config['TESTING'] = True
        
        self.auth_headers = {
            'Authorization': 'Bearer mock-token'
        }
    
    @patch('app.routes.upload_routes.storage')
    @patch('app.routes.auth_routes.verify_token')
    def test_upload_image_success(self, mock_verify, mock_storage):
        """Test successful image upload"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Mock Firebase Storage
        mock_bucket = MagicMock()
        mock_blob = MagicMock()
        mock_blob.public_url = 'https://storage.googleapis.com/bucket/image.jpg'
        mock_bucket.blob.return_value = mock_blob
        mock_storage.bucket.return_value = mock_bucket
        
        # Create fake image file
        data = {
            'file': (io.BytesIO(b'fake image data'), 'test.jpg'),
            'context': 'dish'
        }
        
        response = self.client.post(
            '/api/upload/image',
            headers=self.auth_headers,
            data=data,
            content_type='multipart/form-data'
        )
        
        self.assertEqual(response.status_code, 200)
        result = response.get_json()
        self.assertTrue(result['success'])
        self.assertIn('imageUrl', result)
        self.assertIn('filename', result)
    
    @patch('app.routes.auth_routes.verify_token')
    def test_upload_no_file(self, mock_verify):
        """Test upload without file"""
        mock_verify.return_value = {'uid': 'user123'}
        
        response = self.client.post('/api/upload/image', headers=self.auth_headers)
        
        self.assertEqual(response.status_code, 400)
        data = response.get_json()
        self.assertIn('error', data)
    
    @patch('app.routes.auth_routes.verify_token')
    def test_upload_invalid_type(self, mock_verify):
        """Test upload with invalid file type"""
        mock_verify.return_value = {'uid': 'user123'}
        
        data = {
            'file': (io.BytesIO(b'fake data'), 'test.txt'),  # .txt not allowed
        }
        
        response = self.client.post(
            '/api/upload/image',
            headers=self.auth_headers,
            data=data,
            content_type='multipart/form-data'
        )
        
        self.assertEqual(response.status_code, 400)
        result = response.get_json()
        self.assertIn('error', result)
        self.assertIn('not allowed', result['error'])
    
    @patch('app.routes.upload_routes.storage')
    @patch('app.routes.auth_routes.verify_token')
    def test_upload_multiple_images(self, mock_verify, mock_storage):
        """Test uploading multiple images"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Mock Firebase Storage
        mock_bucket = MagicMock()
        mock_blob = MagicMock()
        mock_blob.public_url = 'https://storage.googleapis.com/bucket/image.jpg'
        mock_bucket.blob.return_value = mock_blob
        mock_storage.bucket.return_value = mock_bucket
        
        # Create multiple fake image files
        data = {
            'files': [
                (io.BytesIO(b'image1'), 'test1.jpg'),
                (io.BytesIO(b'image2'), 'test2.png')
            ],
            'context': 'dish'
        }
        
        response = self.client.post(
            '/api/upload/image/multiple',
            headers=self.auth_headers,
            data=data,
            content_type='multipart/form-data'
        )
        
        self.assertEqual(response.status_code, 200)
        result = response.get_json()
        self.assertTrue(result['success'])
        self.assertIn('images', result)
        self.assertIn('count', result)
    
    @patch('app.routes.upload_routes.storage')
    @patch('app.routes.auth_routes.verify_token')
    def test_upload_too_many_files(self, mock_verify, mock_storage):
        """Test uploading more than 5 files"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Create 6 files (max is 5)
        files = [(io.BytesIO(b'image'), f'test{i}.jpg') for i in range(6)]
        data = {'files': files}
        
        response = self.client.post(
            '/api/upload/image/multiple',
            headers=self.auth_headers,
            data=data,
            content_type='multipart/form-data'
        )
        
        self.assertEqual(response.status_code, 400)
        result = response.get_json()
        self.assertIn('error', result)
    
    @patch('app.routes.upload_routes.storage')
    @patch('app.routes.auth_routes.verify_token')
    def test_delete_image(self, mock_verify, mock_storage):
        """Test deleting an image"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Mock Firebase Storage
        mock_bucket = MagicMock()
        mock_blob = MagicMock()
        mock_bucket.blob.return_value = mock_blob
        mock_storage.bucket.return_value = mock_bucket
        
        response = self.client.post(
            '/api/upload/image/delete',
            headers=self.auth_headers,
            json={'filename': 'dish/user123/test.jpg'}
        )
        
        self.assertEqual(response.status_code, 200)
        result = response.get_json()
        self.assertTrue(result['success'])
        mock_blob.delete.assert_called_once()
    
    @patch('app.routes.auth_routes.verify_token')
    def test_delete_image_unauthorized(self, mock_verify):
        """Test deleting another user's image"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Try to delete another user's file
        response = self.client.post(
            '/api/upload/image/delete',
            headers=self.auth_headers,
            json={'filename': 'dish/user999/test.jpg'}  # Different user
        )
        
        self.assertEqual(response.status_code, 403)
        result = response.get_json()
        self.assertIn('error', result)
    
    @patch('app.routes.auth_routes.verify_token')
    def test_delete_no_filename(self, mock_verify):
        """Test delete without filename"""
        mock_verify.return_value = {'uid': 'user123'}
        
        response = self.client.post(
            '/api/upload/image/delete',
            headers=self.auth_headers,
            json={}
        )
        
        self.assertEqual(response.status_code, 400)
        result = response.get_json()
        self.assertIn('error', result)


if __name__ == '__main__':
    unittest.main()

"""
Unit Tests for Review Management
=================================
Tests review edit, delete, and report functionality
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from application import create_app


class TestReviewManagement(unittest.TestCase):
    
    def setUp(self):
        """Set up test client"""
        self.app = create_app()
        self.client = self.app.test_client()
        self.app.config['TESTING'] = True
        
        self.auth_headers = {
            'Authorization': 'Bearer mock-token',
            'Content-Type': 'application/json'
        }
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_update_review_success(self, mock_verify, mock_db):
        """Test updating own review"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Mock existing review
        mock_review_doc = MagicMock()
        mock_review_doc.exists = True
        mock_review_doc.to_dict.return_value = {
            'userId': 'user123',
            'dishId': 'dish456',
            'rating': 4,
            'comment': 'Good'
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_review_doc
        
        # Mock update
        mock_review_ref = MagicMock()
        mock_db.collection.return_value.document.return_value = mock_review_ref
        
        response = self.client.put(
            '/api/reviews/review123',
            headers=self.auth_headers,
            json={'rating': 5, 'comment': 'Excellent!'}
        )
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data['success'])
        mock_review_ref.update.assert_called_once()
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_update_review_unauthorized(self, mock_verify, mock_db):
        """Test updating another user's review"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Mock review owned by different user
        mock_review_doc = MagicMock()
        mock_review_doc.exists = True
        mock_review_doc.to_dict.return_value = {
            'userId': 'user999',  # Different user
            'rating': 4
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_review_doc
        
        response = self.client.put(
            '/api/reviews/review123',
            headers=self.auth_headers,
            json={'rating': 5}
        )
        
        self.assertEqual(response.status_code, 403)
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_update_review_invalid_rating(self, mock_verify, mock_db):
        """Test updating with invalid rating"""
        mock_verify.return_value = {'uid': 'user123'}
        
        mock_review_doc = MagicMock()
        mock_review_doc.exists = True
        mock_review_doc.to_dict.return_value = {'userId': 'user123'}
        mock_db.collection.return_value.document.return_value.get.return_value = mock_review_doc
        
        response = self.client.put(
            '/api/reviews/review123',
            headers=self.auth_headers,
            json={'rating': 6}  # Invalid (must be 1-5)
        )
        
        self.assertEqual(response.status_code, 400)
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_update_review_not_found(self, mock_verify, mock_db):
        """Test updating non-existent review"""
        mock_verify.return_value = {'uid': 'user123'}
        
        mock_review_doc = MagicMock()
        mock_review_doc.exists = False
        mock_db.collection.return_value.document.return_value.get.return_value = mock_review_doc
        
        response = self.client.put(
            '/api/reviews/nonexistent',
            headers=self.auth_headers,
            json={'rating': 5}
        )
        
        self.assertEqual(response.status_code, 404)
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_delete_review_as_owner(self, mock_verify, mock_db):
        """Test deleting own review"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Mock review
        mock_review_doc = MagicMock()
        mock_review_doc.exists = True
        mock_review_doc.to_dict.return_value = {
            'userId': 'user123',
            'dishId': 'dish456',
            'rating': 4
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_review_doc
        
        # Mock dish reviews for recalculation
        mock_db.collection.return_value.where.return_value.stream.return_value = []
        
        response = self.client.delete('/api/reviews/review123', headers=self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data['success'])
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_delete_review_as_admin(self, mock_verify, mock_db):
        """Test deleting review as admin"""
        mock_verify.return_value = {'uid': 'admin123'}
        
        # Mock review owned by different user
        mock_review_doc = MagicMock()
        mock_review_doc.exists = True
        mock_review_doc.to_dict.return_value = {
            'userId': 'user999',
            'dishId': 'dish456'
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_review_doc
        
        # Mock admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': True}
        
        def mock_get_side_effect(*args):
            if 'users' in str(args):
                return mock_user_doc
            return mock_review_doc
        
        mock_db.collection.return_value.document.return_value.get.side_effect = mock_get_side_effect
        
        # Mock reviews for recalculation
        mock_db.collection.return_value.where.return_value.stream.return_value = []
        
        response = self.client.delete('/api/reviews/review123', headers=self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_delete_review_unauthorized(self, mock_verify, mock_db):
        """Test deleting another user's review without admin"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Mock review owned by different user
        mock_review_doc = MagicMock()
        mock_review_doc.exists = True
        mock_review_doc.to_dict.return_value = {'userId': 'user999'}
        
        # Mock non-admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': False}
        
        def mock_get_side_effect(*args):
            if 'users' in str(args):
                return mock_user_doc
            return mock_review_doc
        
        mock_db.collection.return_value.document.return_value.get.side_effect = mock_get_side_effect
        
        response = self.client.delete('/api/reviews/review123', headers=self.auth_headers)
        
        self.assertEqual(response.status_code, 403)
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_report_review(self, mock_verify, mock_db):
        """Test reporting a review"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Mock review
        mock_review_doc = MagicMock()
        mock_review_doc.exists = True
        mock_db.collection.return_value.document.return_value.get.return_value = mock_review_doc
        
        # Mock update
        mock_review_ref = MagicMock()
        mock_db.collection.return_value.document.return_value = mock_review_ref
        
        response = self.client.post(
            '/api/reviews/review123/report',
            headers=self.auth_headers,
            json={'reason': 'Inappropriate language'}
        )
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data['success'])
        mock_review_ref.update.assert_called_once()
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_report_nonexistent_review(self, mock_verify, mock_db):
        """Test reporting non-existent review"""
        mock_verify.return_value = {'uid': 'user123'}
        
        mock_review_doc = MagicMock()
        mock_review_doc.exists = False
        mock_db.collection.return_value.document.return_value.get.return_value = mock_review_doc
        
        response = self.client.post(
            '/api/reviews/nonexistent/report',
            headers=self.auth_headers,
            json={'reason': 'Test'}
        )
        
        self.assertEqual(response.status_code, 404)
    
    @patch('app.routes.review_routes.db')
    @patch('app.routes.auth_routes.verify_token')
    def test_update_recalculates_rating(self, mock_verify, mock_db):
        """Test that updating review recalculates dish rating"""
        mock_verify.return_value = {'uid': 'user123'}
        
        # Mock review
        mock_review_doc = MagicMock()
        mock_review_doc.exists = True
        mock_review_doc.to_dict.return_value = {
            'userId': 'user123',
            'dishId': 'dish456',
            'rating': 3
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_review_doc
        
        # Mock other reviews for the dish
        mock_review1 = MagicMock()
        mock_review1.to_dict.return_value = {'rating': 4}
        mock_review2 = MagicMock()
        mock_review2.to_dict.return_value = {'rating': 5}
        mock_db.collection.return_value.where.return_value.stream.return_value = [mock_review1, mock_review2]
        
        # Mock dish update
        mock_dish_ref = MagicMock()
        mock_db.collection.return_value.document.return_value = mock_dish_ref
        
        response = self.client.put(
            '/api/reviews/review123',
            headers=self.auth_headers,
            json={'rating': 5}
        )
        
        self.assertEqual(response.status_code, 200)
        # Verify dish rating was updated
        self.assertTrue(mock_dish_ref.update.called)


if __name__ == '__main__':
    unittest.main()

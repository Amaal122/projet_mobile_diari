"""
Unit Tests for Admin Routes
============================
Tests admin panel endpoints
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from application import create_app
from datetime import datetime


class TestAdminRoutes(unittest.TestCase):
    
    def setUp(self):
        """Set up test client"""
        self.app = create_app()
        self.client = self.app.test_client()
        self.app.config['TESTING'] = True
        
        # Mock admin token
        self.admin_headers = {
            'Authorization': 'Bearer mock-admin-token',
            'Content-Type': 'application/json'
        }
    
    @patch('app.routes.admin_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_platform_stats_success(self, mock_verify, mock_db):
        """Test platform statistics endpoint"""
        # Mock admin auth
        mock_verify.return_value = {'uid': 'admin123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': True}
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        # Mock collection counts
        mock_firestore.collection.return_value.stream.return_value = [Mock(), Mock(), Mock()]
        
        response = self.client.get('/api/admin/stats', headers=self.admin_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('totalUsers', data)
        self.assertIn('totalChefs', data)
        self.assertIn('totalOrders', data)
    
    @patch('app.routes.auth_routes.verify_token')
    def test_admin_endpoint_unauthorized(self, mock_verify):
        """Test admin endpoints reject non-admin users"""
        mock_verify.return_value = None
        
        response = self.client.get('/api/admin/stats', headers={'Authorization': 'Bearer invalid'})
        
        self.assertEqual(response.status_code, 401)
    
    @patch('app.routes.admin_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_admin_endpoint_forbidden(self, mock_verify, mock_db):
        """Test admin endpoints reject regular users"""
        mock_verify.return_value = {'uid': 'user123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock non-admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': False}
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        response = self.client.get('/api/admin/stats', headers=self.admin_headers)
        
        self.assertEqual(response.status_code, 403)
    
    @patch('app.routes.admin_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_list_users(self, mock_verify, mock_db):
        """Test list users endpoint"""
        mock_verify.return_value = {'uid': 'admin123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': True}
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        # Mock users
        mock_user = MagicMock()
        mock_user.id = 'user1'
        mock_user.to_dict.return_value = {'name': 'Test User', 'email': 'test@test.com'}
        mock_firestore.collection.return_value.order_by.return_value.limit.return_value.stream.return_value = [mock_user]
        
        response = self.client.get('/api/admin/users?page=1&limit=10', headers=self.admin_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('users', data)
        self.assertIn('page', data)
        self.assertIn('limit', data)
    
    @patch('app.routes.admin_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_ban_user(self, mock_verify, mock_db):
        """Test ban user functionality"""
        mock_verify.return_value = {'uid': 'admin123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': True}
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        # Mock user update
        mock_user_ref = MagicMock()
        mock_firestore.collection.return_value.document.return_value = mock_user_ref
        
        response = self.client.post(
            '/api/admin/users/user123/ban',
            headers=self.admin_headers,
            json={'reason': 'Spam'}
        )
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data['success'])
        mock_user_ref.update.assert_called_once()
    
    @patch('app.routes.admin_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_unban_user(self, mock_verify, mock_db):
        """Test unban user functionality"""
        mock_verify.return_value = {'uid': 'admin123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': True}
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        # Mock user update
        mock_user_ref = MagicMock()
        mock_firestore.collection.return_value.document.return_value = mock_user_ref
        
        response = self.client.post('/api/admin/users/user123/unban', headers=self.admin_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data['success'])
    
    @patch('app.routes.admin_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_list_chefs(self, mock_verify, mock_db):
        """Test list chefs with stats"""
        mock_verify.return_value = {'uid': 'admin123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': True}
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        # Mock chef
        mock_chef = MagicMock()
        mock_chef.id = 'chef1'
        mock_chef.to_dict.return_value = {'name': 'Chef Test'}
        mock_firestore.collection.return_value.stream.return_value = [mock_chef]
        
        # Mock dishes and orders count
        mock_firestore.collection.return_value.where.return_value.stream.return_value = []
        
        response = self.client.get('/api/admin/chefs', headers=self.admin_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('chefs', data)
    
    @patch('app.routes.admin_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_verify_chef(self, mock_verify, mock_db):
        """Test verify chef functionality"""
        mock_verify.return_value = {'uid': 'admin123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': True}
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        # Mock chef update
        mock_chef_ref = MagicMock()
        mock_firestore.collection.return_value.document.return_value = mock_chef_ref
        
        response = self.client.post('/api/admin/chefs/chef123/verify', headers=self.admin_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data['success'])
        mock_chef_ref.update.assert_called_once()
    
    @patch('app.routes.admin_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_get_reports(self, mock_verify, mock_db):
        """Test get reported content"""
        mock_verify.return_value = {'uid': 'admin123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': True}
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        # Mock reported review
        mock_review = MagicMock()
        mock_review.id = 'review1'
        mock_review.to_dict.return_value = {'isReported': True, 'comment': 'Bad review'}
        mock_firestore.collection.return_value.where.return_value.stream.return_value = [mock_review]
        
        response = self.client.get('/api/admin/reports', headers=self.admin_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('reports', data)
    
    @patch('app.routes.admin_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_resolve_report(self, mock_verify, mock_db):
        """Test resolve report functionality"""
        mock_verify.return_value = {'uid': 'admin123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock admin user
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {'isAdmin': True}
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        response = self.client.post(
            '/api/admin/reports/report123/resolve',
            headers=self.admin_headers,
            json={'type': 'review', 'action': 'dismiss'}
        )
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data['success'])


if __name__ == '__main__':
    unittest.main()

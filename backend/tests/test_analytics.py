"""
Unit Tests for Analytics Routes
================================
Tests chef analytics dashboard endpoints
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from application import create_app
from datetime import datetime, timedelta


class TestAnalyticsRoutes(unittest.TestCase):
    
    def setUp(self):
        """Set up test client"""
        self.app = create_app()
        self.client = self.app.test_client()
        self.app.config['TESTING'] = True
        
        # Mock chef token
        self.chef_headers = {
            'Authorization': 'Bearer mock-chef-token',
            'Content-Type': 'application/json'
        }
    
    @patch('app.routes.analytics_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_chef_overview_success(self, mock_verify, mock_db):
        """Test chef overview endpoint returns correct stats"""
        # Mock auth
        mock_verify.return_value = {'uid': 'chef123', 'email': 'chef@test.com'}
        
        # Mock Firestore
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock chef document
        mock_chef_doc = MagicMock()
        mock_chef_doc.exists = True
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_chef_doc
        
        # Mock orders
        mock_order1 = MagicMock()
        mock_order1.to_dict.return_value = {
            'total': 50.0,
            'status': 'delivered',
            'createdAt': datetime.now()
        }
        mock_order2 = MagicMock()
        mock_order2.to_dict.return_value = {
            'total': 75.0,
            'status': 'delivered',
            'createdAt': datetime.now() - timedelta(days=2)
        }
        
        mock_firestore.collection.return_value.where.return_value.stream.return_value = [mock_order1, mock_order2]
        
        # Mock dishes
        mock_firestore.collection.return_value.where.return_value.stream.return_value = []
        
        response = self.client.get('/api/analytics/chef/overview?period=30', headers=self.chef_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('totalOrders', data)
        self.assertIn('totalRevenue', data)
        self.assertIn('periodRevenue', data)
    
    @patch('app.routes.auth_routes.verify_token')
    def test_chef_overview_unauthorized(self, mock_verify):
        """Test chef overview rejects non-chef users"""
        mock_verify.return_value = None
        
        response = self.client.get('/api/analytics/chef/overview', headers={'Authorization': 'Bearer invalid'})
        
        self.assertEqual(response.status_code, 401)
    
    @patch('app.routes.analytics_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_popular_dishes(self, mock_verify, mock_db):
        """Test popular dishes endpoint"""
        mock_verify.return_value = {'uid': 'chef123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock chef exists
        mock_chef_doc = MagicMock()
        mock_chef_doc.exists = True
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_chef_doc
        
        # Mock dishes
        mock_dish = MagicMock()
        mock_dish.id = 'dish1'
        mock_dish.to_dict.return_value = {
            'dishName': 'Couscous',
            'imageUrl': 'http://example.com/img.jpg'
        }
        mock_firestore.collection.return_value.where.return_value.stream.return_value = [mock_dish]
        
        response = self.client.get('/api/analytics/chef/popular-dishes?limit=5', headers=self.chef_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('popularDishes', data)
    
    @patch('app.routes.analytics_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_revenue_chart(self, mock_verify, mock_db):
        """Test revenue chart data"""
        mock_verify.return_value = {'uid': 'chef123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock chef exists
        mock_chef_doc = MagicMock()
        mock_chef_doc.exists = True
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_chef_doc
        
        # Mock orders
        mock_order = MagicMock()
        mock_order.to_dict.return_value = {
            'total': 100.0,
            'createdAt': datetime.now()
        }
        mock_firestore.collection.return_value.where.return_value.stream.return_value = [mock_order]
        
        response = self.client.get('/api/analytics/chef/revenue-chart?days=7', headers=self.chef_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('chartData', data)
        self.assertIsInstance(data['chartData'], list)
    
    @patch('app.routes.analytics_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_customer_insights(self, mock_verify, mock_db):
        """Test customer insights endpoint"""
        mock_verify.return_value = {'uid': 'chef123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock chef exists
        mock_chef_doc = MagicMock()
        mock_chef_doc.exists = True
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_chef_doc
        
        # Mock orders with repeat customer
        mock_order1 = MagicMock()
        mock_order1.to_dict.return_value = {'userId': 'user1', 'total': 50.0}
        mock_order2 = MagicMock()
        mock_order2.to_dict.return_value = {'userId': 'user1', 'total': 60.0}
        mock_order3 = MagicMock()
        mock_order3.to_dict.return_value = {'userId': 'user2', 'total': 40.0}
        
        mock_firestore.collection.return_value.where.return_value.stream.return_value = [
            mock_order1, mock_order2, mock_order3
        ]
        
        response = self.client.get('/api/analytics/chef/customer-insights', headers=self.chef_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('totalCustomers', data)
        self.assertIn('repeatCustomers', data)
        self.assertIn('repeatRate', data)
        self.assertIn('topCustomers', data)
    
    @patch('app.routes.analytics_routes.get_db')
    @patch('app.routes.auth_routes.verify_token')
    def test_peak_hours(self, mock_verify, mock_db):
        """Test peak hours endpoint"""
        mock_verify.return_value = {'uid': 'chef123'}
        
        mock_firestore = MagicMock()
        mock_db.return_value = mock_firestore
        
        # Mock chef exists
        mock_chef_doc = MagicMock()
        mock_chef_doc.exists = True
        mock_firestore.collection.return_value.document.return_value.get.return_value = mock_chef_doc
        
        # Mock orders at different hours
        orders = []
        for hour in [12, 12, 18, 19, 19, 19]:  # Lunch and dinner peaks
            mock_order = MagicMock()
            order_time = datetime.now().replace(hour=hour, minute=0)
            mock_order.to_dict.return_value = {'createdAt': order_time}
            orders.append(mock_order)
        
        mock_firestore.collection.return_value.where.return_value.stream.return_value = orders
        
        response = self.client.get('/api/analytics/chef/peak-hours', headers=self.chef_headers)
        
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('peakHours', data)
        self.assertEqual(len(data['peakHours']), 24)  # All 24 hours


if __name__ == '__main__':
    unittest.main()

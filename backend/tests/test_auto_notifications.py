"""
Unit Tests for Auto-Notifications
==================================
Tests automatic notification system
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.auto_notifications import (
    notify_order_created,
    notify_order_accepted,
    notify_order_ready,
    notify_order_delivered,
    notify_order_cancelled,
    notify_new_review,
    handle_order_status_change
)


class TestAutoNotifications(unittest.TestCase):
    
    @patch('app.services.auto_notifications.send_notification')
    @patch('app.services.auto_notifications.db')
    def test_notify_order_created(self, mock_db, mock_send):
        """Test new order notification to chef"""
        # Mock customer data
        mock_customer = MagicMock()
        mock_customer.exists = True
        mock_customer.to_dict.return_value = {'name': 'John Doe'}
        mock_db.collection.return_value.document.return_value.get.return_value = mock_customer
        
        order_data = {
            'cookerId': 'chef123',
            'userId': 'user456',
            'total': 50.0
        }
        
        notify_order_created('order789', order_data)
        
        # Verify notification was sent
        mock_send.assert_called_once()
        call_args = mock_send.call_args
        self.assertEqual(call_args[1]['user_id'], 'chef123')
        self.assertIn('طلب جديد', call_args[1]['title'])
    
    @patch('app.services.auto_notifications.send_notification')
    @patch('app.services.auto_notifications.db')
    def test_notify_order_accepted(self, mock_db, mock_send):
        """Test order accepted notification to customer"""
        # Mock chef data
        mock_chef = MagicMock()
        mock_chef.exists = True
        mock_chef.to_dict.return_value = {'name': 'Chef Ali'}
        mock_db.collection.return_value.document.return_value.get.return_value = mock_chef
        
        order_data = {
            'userId': 'user456',
            'cookerId': 'chef123'
        }
        
        notify_order_accepted('order789', order_data)
        
        mock_send.assert_called_once()
        call_args = mock_send.call_args
        self.assertEqual(call_args[1]['user_id'], 'user456')
        self.assertIn('تم قبول', call_args[1]['title'])
    
    @patch('app.services.auto_notifications.send_notification')
    def test_notify_order_ready(self, mock_send):
        """Test order ready notification"""
        order_data = {'userId': 'user456'}
        
        notify_order_ready('order789', order_data)
        
        mock_send.assert_called_once()
        call_args = mock_send.call_args
        self.assertEqual(call_args[1]['user_id'], 'user456')
        self.assertIn('جاهز', call_args[1]['title'])
    
    @patch('app.services.auto_notifications.send_notification')
    def test_notify_order_delivered(self, mock_send):
        """Test order delivered notification"""
        order_data = {'userId': 'user456'}
        
        notify_order_delivered('order789', order_data)
        
        mock_send.assert_called_once()
        call_args = mock_send.call_args
        self.assertEqual(call_args[1]['user_id'], 'user456')
        self.assertIn('تم التوصيل', call_args[1]['title'])
    
    @patch('app.services.auto_notifications.send_notification')
    def test_notify_order_cancelled_by_customer(self, mock_send):
        """Test cancellation notification when customer cancels"""
        order_data = {
            'userId': 'user456',
            'cookerId': 'chef123',
            'cancelledBy': 'user456'
        }
        
        notify_order_cancelled('order789', order_data)
        
        # Should notify chef
        mock_send.assert_called_once()
        call_args = mock_send.call_args
        self.assertEqual(call_args[1]['user_id'], 'chef123')
    
    @patch('app.services.auto_notifications.send_notification')
    def test_notify_order_cancelled_by_chef(self, mock_send):
        """Test cancellation notification when chef cancels"""
        order_data = {
            'userId': 'user456',
            'cookerId': 'chef123',
            'cancelledBy': 'chef123'
        }
        
        notify_order_cancelled('order789', order_data)
        
        # Should notify customer
        mock_send.assert_called_once()
        call_args = mock_send.call_args
        self.assertEqual(call_args[1]['user_id'], 'user456')
    
    @patch('app.services.auto_notifications.send_notification')
    @patch('app.services.auto_notifications.db')
    def test_notify_new_review(self, mock_db, mock_send):
        """Test new review notification to chef"""
        # Mock dish data
        mock_dish = MagicMock()
        mock_dish.exists = True
        mock_dish.to_dict.return_value = {
            'cookerId': 'chef123',
            'name': 'Couscous'
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_dish
        
        review_data = {
            'dishId': 'dish456',
            'rating': 5
        }
        
        notify_new_review('review789', review_data)
        
        mock_send.assert_called_once()
        call_args = mock_send.call_args
        self.assertEqual(call_args[1]['user_id'], 'chef123')
        self.assertIn('تقييم', call_args[1]['title'])
    
    @patch('app.services.auto_notifications.notify_order_created')
    def test_handle_status_change_pending(self, mock_notify):
        """Test status change handler for pending orders"""
        order_data = {'userId': 'user456', 'cookerId': 'chef123'}
        
        handle_order_status_change('order789', None, 'pending', order_data)
        
        mock_notify.assert_called_once_with('order789', order_data)
    
    @patch('app.services.auto_notifications.notify_order_accepted')
    def test_handle_status_change_accepted(self, mock_notify):
        """Test status change handler for accepted orders"""
        order_data = {'userId': 'user456', 'cookerId': 'chef123'}
        
        handle_order_status_change('order789', 'pending', 'accepted', order_data)
        
        mock_notify.assert_called_once_with('order789', order_data)
    
    @patch('app.services.auto_notifications.notify_order_ready')
    def test_handle_status_change_ready(self, mock_notify):
        """Test status change handler for ready orders"""
        order_data = {'userId': 'user456'}
        
        handle_order_status_change('order789', 'accepted', 'ready', order_data)
        
        mock_notify.assert_called_once_with('order789', order_data)
    
    @patch('app.services.auto_notifications.notify_order_delivered')
    def test_handle_status_change_delivered(self, mock_notify):
        """Test status change handler for delivered orders"""
        order_data = {'userId': 'user456'}
        
        handle_order_status_change('order789', 'delivering', 'delivered', order_data)
        
        mock_notify.assert_called_once_with('order789', order_data)
    
    @patch('app.services.auto_notifications.notify_order_cancelled')
    def test_handle_status_change_cancelled(self, mock_notify):
        """Test status change handler for cancelled orders"""
        order_data = {'userId': 'user456', 'cancelledBy': 'user456'}
        
        handle_order_status_change('order789', 'pending', 'cancelled', order_data)
        
        mock_notify.assert_called_once_with('order789', order_data)
    
    def test_handle_status_change_unknown_status(self):
        """Test handler with unknown status (should not crash)"""
        order_data = {'userId': 'user456'}
        
        # Should not raise exception
        try:
            handle_order_status_change('order789', 'pending', 'unknown_status', order_data)
        except Exception as e:
            self.fail(f"Handler raised exception for unknown status: {e}")


if __name__ == '__main__':
    unittest.main()

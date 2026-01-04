"""
Unit Test Runner
================
Run all unit tests for new features
"""

import unittest
import sys
import os
from unittest.mock import MagicMock, patch

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Mock Firebase before any imports
sys.modules['firebase_admin'] = MagicMock()
sys.modules['firebase_admin.firestore'] = MagicMock()
sys.modules['firebase_admin.storage'] = MagicMock()
sys.modules['firebase_admin.messaging'] = MagicMock()

# Import test modules
from tests.test_analytics import TestAnalyticsRoutes
from tests.test_admin import TestAdminRoutes
from tests.test_upload import TestUploadRoutes
from tests.test_auto_notifications import TestAutoNotifications
from tests.test_review_management import TestReviewManagement


def suite():
    """Create test suite"""
    test_suite = unittest.TestSuite()
    
    # Add all test classes
    test_suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestAnalyticsRoutes))
    test_suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestAdminRoutes))
    test_suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestUploadRoutes))
    test_suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestAutoNotifications))
    test_suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestReviewManagement))
    
    return test_suite


if __name__ == '__main__':
    print("="*70)
    print("UNIT TESTS FOR NEW FEATURES")
    print("="*70)
    print("\nRunning tests for:")
    print("  ✓ Analytics Routes")
    print("  ✓ Admin Routes")
    print("  ✓ Upload Routes")
    print("  ✓ Auto-Notifications")
    print("  ✓ Review Management")
    print("\n" + "="*70 + "\n")
    
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite())
    
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    print(f"Tests run: {result.testsRun}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print(f"Skipped: {len(result.skipped)}")
    print(f"Success rate: {(result.testsRun - len(result.failures) - len(result.errors)) / result.testsRun * 100:.1f}%")
    
    if result.wasSuccessful():
        print("\n✅ ALL TESTS PASSED!")
        sys.exit(0)
    else:
        print("\n❌ SOME TESTS FAILED")
        sys.exit(1)

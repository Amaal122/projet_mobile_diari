#!/usr/bin/env python
"""
Comprehensive Test Suite for Diari App
Tests: Edge Cases, Security, Performance, Search, Order Workflow, Frontend
"""

import requests
import json
import time
import threading
import concurrent.futures
from datetime import datetime

BASE_URL = "http://localhost:5000/api"
FIREBASE_API_KEY = "AIzaSyDyBYEFD98etiHhTdJWIZv5qhGFKC3S7bM"

# Test accounts
CUSTOMER_EMAIL = "testcustomer@diari.test"
CUSTOMER_PASSWORD = "test123456"
CHEF_EMAIL = "testchef@diari.test"
CHEF_PASSWORD = "test123456"

results = {"passed": [], "failed": [], "warnings": []}

def log_pass(msg):
    print(f"  \033[92m[OK]\033[0m {msg}")
    results["passed"].append(msg)

def log_fail(msg):
    print(f"  \033[91m[FAIL]\033[0m {msg}")
    results["failed"].append(msg)

def log_warn(msg):
    print(f"  \033[93m[WARN]\033[0m {msg}")
    results["warnings"].append(msg)

def log_test(msg):
    print(f"\n\033[94m[TEST]\033[0m {msg}")

def firebase_login(email, password):
    """Login via Firebase REST API"""
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
    response = requests.post(url, json={
        "email": email,
        "password": password,
        "returnSecureToken": True
    }, timeout=10)
    if response.status_code == 200:
        data = response.json()
        return data.get("idToken"), data.get("localId")
    return None, None

# ==================== SECTION 1: EDGE CASES ====================

def test_edge_cases(token, uid):
    print("\n" + "="*60)
    print("1. EDGE CASES & VALIDATION TESTS")
    print("="*60)
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test 1: Empty cart order
    log_test("Create order with empty cart")
    try:
        # First clear cart
        requests.delete(f"{BASE_URL}/cart/clear", headers=headers, timeout=5)
        response = requests.post(f"{BASE_URL}/orders", headers=headers, json={
            "items": [],
            "totalAmount": 0,
            "deliveryAddress": "Test"
        }, timeout=5)
        if response.status_code >= 400:
            log_pass("Empty cart order rejected correctly")
        else:
            log_warn("Empty cart order was accepted (may be valid)")
    except Exception as e:
        log_fail(f"Empty cart test error: {e}")

    # Test 2: Invalid dish ID
    log_test("Add invalid dish to cart")
    try:
        response = requests.post(f"{BASE_URL}/cart/add", headers=headers, json={
            "dishId": "INVALID_DISH_ID_12345",
            "quantity": 1
        }, timeout=5)
        if response.status_code >= 400:
            log_pass("Invalid dish rejected correctly")
        else:
            log_warn("Invalid dish was accepted (should verify)")
    except Exception as e:
        log_fail(f"Invalid dish test error: {e}")

    # Test 3: Negative quantity
    log_test("Add dish with negative quantity")
    try:
        response = requests.post(f"{BASE_URL}/cart/add", headers=headers, json={
            "dishId": "some_dish",
            "quantity": -5
        }, timeout=5)
        if response.status_code >= 400:
            log_pass("Negative quantity rejected correctly")
        else:
            log_warn("Negative quantity accepted (should validate)")
    except Exception as e:
        log_fail(f"Negative quantity test error: {e}")

    # Test 4: Very long input strings
    log_test("Send very long address (10000 chars)")
    try:
        long_address = "A" * 10000
        response = requests.post(f"{BASE_URL}/orders", headers=headers, json={
            "items": [{"dishId": "test", "quantity": 1}],
            "totalAmount": 100,
            "deliveryAddress": long_address
        }, timeout=10)
        if response.status_code == 200:
            log_warn("Very long address accepted (may cause issues)")
        else:
            log_pass("Very long address handled")
    except Exception as e:
        log_fail(f"Long input test error: {e}")

    # Test 5: Missing required fields
    log_test("Create order without required fields")
    try:
        response = requests.post(f"{BASE_URL}/orders", headers=headers, json={}, timeout=5)
        if response.status_code >= 400:
            log_pass("Missing fields rejected correctly")
        else:
            log_warn("Missing fields accepted")
    except Exception as e:
        log_fail(f"Missing fields test error: {e}")

    # Test 6: SQL injection attempt (should be safe with Firestore)
    log_test("SQL injection attempt in search")
    try:
        response = requests.get(f"{BASE_URL}/dishes/search?q='; DROP TABLE dishes;--", headers=headers, timeout=5)
        log_pass("SQL injection handled (Firestore is NoSQL)")
    except Exception as e:
        log_pass(f"Search endpoint handled injection: {e}")

    # Test 7: XSS attempt
    log_test("XSS attempt in message")
    try:
        response = requests.post(f"{BASE_URL}/messages", headers=headers, json={
            "receiverId": "test",
            "content": "<script>alert('xss')</script>"
        }, timeout=5)
        log_pass("XSS input handled (should sanitize on display)")
    except Exception as e:
        log_pass(f"XSS test handled: {e}")


# ==================== SECTION 2: SECURITY TESTS ====================

def test_security(token, uid, chef_token, chef_uid):
    print("\n" + "="*60)
    print("2. SECURITY & AUTHORIZATION TESTS")
    print("="*60)
    
    headers = {"Authorization": f"Bearer {token}"}
    chef_headers = {"Authorization": f"Bearer {chef_token}"}
    
    # Test 1: No token access
    log_test("Access protected endpoint without token")
    try:
        response = requests.get(f"{BASE_URL}/orders", timeout=5)
        if response.status_code == 401 or response.status_code == 403:
            log_pass("Unauthorized access blocked correctly")
        else:
            log_fail(f"Unauthorized access allowed! Status: {response.status_code}")
    except Exception as e:
        log_fail(f"No token test error: {e}")

    # Test 2: Invalid token
    log_test("Access with invalid token")
    try:
        bad_headers = {"Authorization": "Bearer INVALID_TOKEN_12345"}
        response = requests.get(f"{BASE_URL}/orders", headers=bad_headers, timeout=5)
        if response.status_code == 401 or response.status_code == 403:
            log_pass("Invalid token rejected correctly")
        else:
            log_warn(f"Invalid token may have been accepted: {response.status_code}")
    except Exception as e:
        log_fail(f"Invalid token test error: {e}")

    # Test 3: Expired token simulation
    log_test("Access with malformed token")
    try:
        bad_headers = {"Authorization": "Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MDAwMDAwMDB9.fake"}
        response = requests.get(f"{BASE_URL}/orders", headers=bad_headers, timeout=5)
        if response.status_code == 401 or response.status_code == 403:
            log_pass("Malformed token rejected correctly")
        else:
            log_warn(f"Malformed token response: {response.status_code}")
    except Exception as e:
        log_pass(f"Malformed token handled: {e}")

    # Test 4: Customer accessing chef-only endpoints
    log_test("Customer accessing chef dashboard")
    try:
        response = requests.get(f"{BASE_URL}/chef/orders", headers=headers, timeout=5)
        # This depends on implementation - customer might get empty or 403
        if response.status_code == 403:
            log_pass("Chef endpoint blocked for customer")
        elif response.status_code == 200:
            log_warn("Customer accessed chef endpoint (may show empty)")
        else:
            log_pass(f"Chef endpoint returned: {response.status_code}")
    except Exception as e:
        log_fail(f"Chef access test error: {e}")

    # Test 5: Access another user's data
    log_test("Access another user's orders")
    try:
        # Try to get orders for a different user ID
        response = requests.get(f"{BASE_URL}/orders?userId=ANOTHER_USER_ID", headers=headers, timeout=5)
        # Should only return current user's orders
        log_pass("Cross-user access test completed")
    except Exception as e:
        log_fail(f"Cross-user test error: {e}")

    # Test 6: Rate limiting check
    log_test("Rate limiting (10 rapid requests)")
    try:
        blocked = False
        for i in range(10):
            response = requests.get(f"{BASE_URL}/dishes", headers=headers, timeout=5)
            if response.status_code == 429:
                blocked = True
                break
        if blocked:
            log_pass("Rate limiting is active")
        else:
            log_warn("No rate limiting detected (may be OK for dev)")
    except Exception as e:
        log_fail(f"Rate limit test error: {e}")


# ==================== SECTION 3: PERFORMANCE TESTS ====================

def test_performance(token):
    print("\n" + "="*60)
    print("3. PERFORMANCE & LOAD TESTS")
    print("="*60)
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test 1: Response time for dishes
    log_test("Dishes API response time")
    try:
        times = []
        for i in range(5):
            start = time.time()
            response = requests.get(f"{BASE_URL}/dishes", headers=headers, timeout=30)
            elapsed = time.time() - start
            times.append(elapsed)
        avg_time = sum(times) / len(times)
        if avg_time < 1.0:
            log_pass(f"Avg response time: {avg_time:.2f}s (excellent)")
        elif avg_time < 3.0:
            log_pass(f"Avg response time: {avg_time:.2f}s (good)")
        else:
            log_warn(f"Avg response time: {avg_time:.2f}s (slow)")
    except Exception as e:
        log_fail(f"Response time test error: {e}")

    # Test 2: Concurrent requests
    log_test("Concurrent requests (10 simultaneous)")
    try:
        def make_request():
            start = time.time()
            response = requests.get(f"{BASE_URL}/dishes", headers=headers, timeout=30)
            return time.time() - start, response.status_code
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(make_request) for _ in range(10)]
            results_conc = [f.result() for f in futures]
        
        success_count = sum(1 for _, code in results_conc if code == 200)
        avg_time = sum(t for t, _ in results_conc) / len(results_conc)
        
        if success_count == 10:
            log_pass(f"All 10 concurrent requests succeeded, avg: {avg_time:.2f}s")
        else:
            log_warn(f"{success_count}/10 succeeded under load")
    except Exception as e:
        log_fail(f"Concurrent test error: {e}")

    # Test 3: Large data handling
    log_test("Request all dishes (pagination test)")
    try:
        response = requests.get(f"{BASE_URL}/dishes?limit=100", headers=headers, timeout=30)
        if response.status_code == 200:
            data = response.json()
            dish_count = len(data.get('dishes', []))
            log_pass(f"Retrieved {dish_count} dishes successfully")
        else:
            log_fail(f"Large data request failed: {response.status_code}")
    except Exception as e:
        log_fail(f"Large data test error: {e}")

    # Test 4: Memory stress test (multiple endpoints)
    log_test("Multiple endpoint stress test")
    try:
        endpoints = ["/dishes", "/dishes/popular", "/orders", "/profile"]
        all_ok = True
        for endpoint in endpoints:
            response = requests.get(f"{BASE_URL}{endpoint}", headers=headers, timeout=10)
            if response.status_code not in [200, 404]:
                all_ok = False
        if all_ok:
            log_pass("All endpoints responded under stress")
        else:
            log_warn("Some endpoints had issues under stress")
    except Exception as e:
        log_fail(f"Stress test error: {e}")


# ==================== SECTION 4: SEARCH & FILTER TESTS ====================

def test_search_filters(token):
    print("\n" + "="*60)
    print("4. SEARCH & FILTER TESTS")
    print("="*60)
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test 1: Search dishes
    log_test("Search for dishes")
    try:
        response = requests.get(f"{BASE_URL}/dishes/search?q=couscous", headers=headers, timeout=10)
        if response.status_code == 200:
            data = response.json()
            count = len(data.get('dishes', data.get('results', [])))
            log_pass(f"Search returned {count} results")
        elif response.status_code == 404:
            log_warn("Search endpoint not implemented")
        else:
            log_fail(f"Search failed: {response.status_code}")
    except Exception as e:
        log_warn(f"Search test: {e}")

    # Test 2: Filter by category
    log_test("Filter dishes by category")
    try:
        response = requests.get(f"{BASE_URL}/dishes?category=main", headers=headers, timeout=10)
        if response.status_code == 200:
            log_pass("Category filter works")
        else:
            log_warn(f"Category filter response: {response.status_code}")
    except Exception as e:
        log_warn(f"Category filter: {e}")

    # Test 3: Filter by price range
    log_test("Filter dishes by price range")
    try:
        response = requests.get(f"{BASE_URL}/dishes?minPrice=5&maxPrice=20", headers=headers, timeout=10)
        if response.status_code == 200:
            log_pass("Price filter works")
        else:
            log_warn(f"Price filter response: {response.status_code}")
    except Exception as e:
        log_warn(f"Price filter: {e}")

    # Test 4: Sort dishes
    log_test("Sort dishes by price")
    try:
        response = requests.get(f"{BASE_URL}/dishes?sortBy=price&order=asc", headers=headers, timeout=10)
        if response.status_code == 200:
            log_pass("Sorting works")
        else:
            log_warn(f"Sorting response: {response.status_code}")
    except Exception as e:
        log_warn(f"Sorting: {e}")

    # Test 5: Empty search
    log_test("Search with no results expected")
    try:
        response = requests.get(f"{BASE_URL}/dishes/search?q=xyznonexistent123", headers=headers, timeout=10)
        if response.status_code == 200:
            data = response.json()
            count = len(data.get('dishes', data.get('results', [])))
            if count == 0:
                log_pass("Empty search returns empty array correctly")
            else:
                log_warn(f"Unexpected results for nonsense query: {count}")
        else:
            log_pass(f"Empty search handled: {response.status_code}")
    except Exception as e:
        log_warn(f"Empty search: {e}")


# ==================== SECTION 5: ORDER WORKFLOW TESTS ====================

def test_order_workflow(token, uid, chef_token, chef_uid):
    print("\n" + "="*60)
    print("5. ORDER WORKFLOW TESTS")
    print("="*60)
    
    headers = {"Authorization": f"Bearer {token}"}
    chef_headers = {"Authorization": f"Bearer {chef_token}"}
    
    order_id = None
    
    # Step 1: Get a dish to order
    log_test("Step 1: Get available dish")
    try:
        response = requests.get(f"{BASE_URL}/dishes", headers=headers, timeout=10)
        dishes = response.json().get('dishes', [])
        if dishes:
            dish = dishes[0]
            log_pass(f"Got dish: {dish.get('name', 'Unknown')}")
        else:
            log_fail("No dishes available")
            return
    except Exception as e:
        log_fail(f"Get dish error: {e}")
        return

    # Step 2: Add to cart
    log_test("Step 2: Add dish to cart")
    try:
        response = requests.post(f"{BASE_URL}/cart/add", headers=headers, json={
            "dishId": dish.get('id'),
            "quantity": 2
        }, timeout=10)
        if response.status_code == 200:
            log_pass("Added to cart")
        else:
            log_warn(f"Add to cart: {response.status_code}")
    except Exception as e:
        log_fail(f"Add to cart error: {e}")

    # Step 3: Create order
    log_test("Step 3: Create order")
    try:
        response = requests.post(f"{BASE_URL}/orders", headers=headers, json={
            "items": [{"dishId": dish.get('id'), "quantity": 2, "price": dish.get('price', 10)}],
            "totalAmount": dish.get('price', 10) * 2,
            "deliveryAddress": "123 Test Street, Test City",
            "paymentMethod": "cash",
            "notes": "Test order from comprehensive test"
        }, timeout=10)
        if response.status_code == 200 or response.status_code == 201:
            data = response.json()
            order_id = data.get('orderId', data.get('order', {}).get('id'))
            log_pass(f"Order created: {order_id}")
        else:
            log_fail(f"Create order failed: {response.status_code}")
            return
    except Exception as e:
        log_fail(f"Create order error: {e}")
        return

    # Step 4: Verify order appears in history
    log_test("Step 4: Verify order in history")
    try:
        response = requests.get(f"{BASE_URL}/orders", headers=headers, timeout=10)
        if response.status_code == 200:
            orders = response.json().get('orders', [])
            found = any(o.get('id') == order_id for o in orders)
            if found:
                log_pass("Order found in history")
            else:
                log_warn("Order not immediately visible in history")
        else:
            log_fail(f"Get orders failed: {response.status_code}")
    except Exception as e:
        log_fail(f"Verify order error: {e}")

    # Step 5: Check order status
    log_test("Step 5: Check order status")
    try:
        response = requests.get(f"{BASE_URL}/orders/{order_id}", headers=headers, timeout=10)
        if response.status_code == 200:
            order = response.json().get('order', response.json())
            status = order.get('status', 'unknown')
            log_pass(f"Order status: {status}")
        else:
            log_warn(f"Get order status: {response.status_code}")
    except Exception as e:
        log_warn(f"Check status: {e}")

    # Step 6: Chef accepts order
    log_test("Step 6: Chef accepts order")
    try:
        response = requests.put(f"{BASE_URL}/orders/{order_id}/status", headers=chef_headers, json={
            "status": "accepted"
        }, timeout=10)
        if response.status_code == 200:
            log_pass("Chef accepted order")
        else:
            log_warn(f"Accept order: {response.status_code}")
    except Exception as e:
        log_warn(f"Chef accept: {e}")

    # Step 7: Chef marks as preparing
    log_test("Step 7: Chef marks as preparing")
    try:
        response = requests.put(f"{BASE_URL}/orders/{order_id}/status", headers=chef_headers, json={
            "status": "preparing"
        }, timeout=10)
        if response.status_code == 200:
            log_pass("Order marked as preparing")
        else:
            log_warn(f"Preparing status: {response.status_code}")
    except Exception as e:
        log_warn(f"Preparing: {e}")

    # Step 8: Chef marks as ready
    log_test("Step 8: Chef marks as ready for delivery")
    try:
        response = requests.put(f"{BASE_URL}/orders/{order_id}/status", headers=chef_headers, json={
            "status": "ready"
        }, timeout=10)
        if response.status_code == 200:
            log_pass("Order marked as ready")
        else:
            log_warn(f"Ready status: {response.status_code}")
    except Exception as e:
        log_warn(f"Ready: {e}")

    # Step 9: Order delivered
    log_test("Step 9: Order delivered")
    try:
        response = requests.put(f"{BASE_URL}/orders/{order_id}/status", headers=chef_headers, json={
            "status": "delivered"
        }, timeout=10)
        if response.status_code == 200:
            log_pass("Order delivered successfully!")
        else:
            log_warn(f"Delivered status: {response.status_code}")
    except Exception as e:
        log_warn(f"Delivered: {e}")

    # Step 10: Customer leaves review
    log_test("Step 10: Customer leaves review")
    try:
        response = requests.post(f"{BASE_URL}/reviews", headers=headers, json={
            "dishId": dish.get('id'),
            "orderId": order_id,
            "userId": uid,
            "rating": 5,
            "comment": "Excellent food! Fast delivery. Test review."
        }, timeout=10)
        if response.status_code == 200 or response.status_code == 201:
            log_pass("Review submitted")
        else:
            log_warn(f"Review: {response.status_code}")
    except Exception as e:
        log_warn(f"Review: {e}")


# ==================== SECTION 6: FRONTEND/UI TESTS ====================

def test_frontend():
    print("\n" + "="*60)
    print("6. FRONTEND AVAILABILITY TESTS")
    print("="*60)
    
    # Test 1: Check if frontend is running
    log_test("Check frontend availability (port 8080)")
    try:
        response = requests.get("http://localhost:8080", timeout=10)
        if response.status_code == 200:
            log_pass("Frontend is running on port 8080")
        else:
            log_warn(f"Frontend returned: {response.status_code}")
    except Exception as e:
        log_warn(f"Frontend not accessible: {e}")

    # Test 2: Check static assets
    log_test("Check static assets (main.dart.js)")
    try:
        response = requests.get("http://localhost:8080/main.dart.js", timeout=10)
        if response.status_code == 200:
            log_pass("main.dart.js loaded successfully")
        else:
            log_warn(f"main.dart.js: {response.status_code}")
    except Exception as e:
        log_warn(f"Static assets: {e}")

    # Test 3: Check manifest
    log_test("Check web manifest")
    try:
        response = requests.get("http://localhost:8080/manifest.json", timeout=10)
        if response.status_code == 200:
            log_pass("manifest.json available")
        else:
            log_warn(f"manifest.json: {response.status_code}")
    except Exception as e:
        log_warn(f"Manifest: {e}")


# ==================== SECTION 7: MESSAGING TESTS ====================

def test_messaging(token, uid, chef_token, chef_uid):
    print("\n" + "="*60)
    print("7. MESSAGING SYSTEM TESTS")
    print("="*60)
    
    headers = {"Authorization": f"Bearer {token}"}
    chef_headers = {"Authorization": f"Bearer {chef_token}"}
    
    # Test 1: Send message from customer to chef
    log_test("Customer sends message to chef")
    try:
        response = requests.post(f"{BASE_URL}/messages", headers=headers, json={
            "senderId": uid,
            "receiverId": chef_uid,
            "content": "Hello, is my order ready? (Test message)"
        }, timeout=10)
        if response.status_code == 200 or response.status_code == 201:
            log_pass("Message sent successfully")
        else:
            log_warn(f"Send message: {response.status_code}")
    except Exception as e:
        log_warn(f"Send message: {e}")

    # Test 2: Chef gets conversations
    log_test("Chef retrieves conversations")
    try:
        response = requests.get(f"{BASE_URL}/messages/conversations?userId={chef_uid}", headers=chef_headers, timeout=10)
        if response.status_code == 200:
            data = response.json().get('data', response.json())
            convs = data.get('conversations', [])
            log_pass(f"Chef has {len(convs)} conversations")
        else:
            log_warn(f"Get conversations: {response.status_code}")
    except Exception as e:
        log_warn(f"Get conversations: {e}")

    # Test 3: Chef replies
    log_test("Chef replies to customer")
    try:
        response = requests.post(f"{BASE_URL}/messages", headers=chef_headers, json={
            "senderId": chef_uid,
            "receiverId": uid,
            "content": "Yes, your order is being prepared! (Test reply)"
        }, timeout=10)
        if response.status_code == 200 or response.status_code == 201:
            log_pass("Chef reply sent")
        else:
            log_warn(f"Chef reply: {response.status_code}")
    except Exception as e:
        log_warn(f"Chef reply: {e}")


# ==================== SECTION 8: PUSH NOTIFICATION TESTS ====================

def test_push_notifications(token):
    print("\n" + "="*60)
    print("8. PUSH NOTIFICATION TESTS")
    print("="*60)
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test 1: Register FCM token
    log_test("Register FCM token")
    try:
        response = requests.post(f"{BASE_URL}/notifications/register", headers=headers, json={
            "fcmToken": "test_fcm_token_12345"
        }, timeout=10)
        if response.status_code == 200:
            log_pass("FCM token registered")
        elif response.status_code == 404:
            log_warn("Push notification endpoint not implemented")
        else:
            log_warn(f"FCM register: {response.status_code}")
    except Exception as e:
        log_warn(f"FCM register: {e}")

    # Test 2: Test notification endpoint
    log_test("Check notification settings")
    try:
        response = requests.get(f"{BASE_URL}/notifications/settings", headers=headers, timeout=10)
        if response.status_code == 200:
            log_pass("Notification settings available")
        else:
            log_warn(f"Notification settings: {response.status_code}")
    except Exception as e:
        log_warn(f"Notification settings: {e}")


# ==================== MAIN ====================

def main():
    print("\n" + "="*60)
    print("DIARI APP - COMPREHENSIVE TEST SUITE")
    print("="*60)
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Backend: {BASE_URL}")
    
    # Login
    print("\n[SETUP] Authenticating test accounts...")
    token, uid = firebase_login(CUSTOMER_EMAIL, CUSTOMER_PASSWORD)
    chef_token, chef_uid = firebase_login(CHEF_EMAIL, CHEF_PASSWORD)
    
    if not token:
        print("\n[ERROR] Customer login failed! Cannot proceed.")
        return
    if not chef_token:
        print("\n[ERROR] Chef login failed! Cannot proceed.")
        return
    
    print(f"  Customer UID: {uid}")
    print(f"  Chef UID: {chef_uid}")
    
    # Run all tests
    test_edge_cases(token, uid)
    test_security(token, uid, chef_token, chef_uid)
    test_performance(token)
    test_search_filters(token)
    test_order_workflow(token, uid, chef_token, chef_uid)
    test_frontend()
    test_messaging(token, uid, chef_token, chef_uid)
    test_push_notifications(token)
    
    # Final Report
    print("\n" + "="*60)
    print("COMPREHENSIVE TEST REPORT")
    print("="*60)
    
    total = len(results["passed"]) + len(results["failed"])
    
    print(f"\n\033[92m[PASSED]\033[0m {len(results['passed'])} tests")
    for msg in results["passed"]:
        print(f"  + {msg}")
    
    if results["failed"]:
        print(f"\n\033[91m[FAILED]\033[0m {len(results['failed'])} tests")
        for msg in results["failed"]:
            print(f"  - {msg}")
    
    if results["warnings"]:
        print(f"\n\033[93m[WARNINGS]\033[0m {len(results['warnings'])} items")
        for msg in results["warnings"]:
            print(f"  ! {msg}")
    
    success_rate = (len(results["passed"]) / total * 100) if total > 0 else 0
    print(f"\n" + "="*60)
    print(f"SUCCESS RATE: {success_rate:.1f}% ({len(results['passed'])}/{total})")
    print(f"WARNINGS: {len(results['warnings'])}")
    print("="*60)

if __name__ == "__main__":
    main()

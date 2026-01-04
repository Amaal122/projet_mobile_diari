"""
Verify test accounts exist and can login
"""
from app.services.firebase_service import init_firebase
import firebase_admin
from firebase_admin import auth
import requests

init_firebase()

print("=== CHECKING TEST ACCOUNTS ===\n")

# Check if accounts exist
try:
    customer = auth.get_user_by_email('testcustomer@diari.test')
    print(f"[OK] Customer exists: {customer.uid}")
    print(f"     Email: {customer.email}")
    print(f"     Verified: {customer.email_verified}")
except Exception as e:
    print(f"[FAIL] Customer: {e}")

try:
    chef = auth.get_user_by_email('testchef@diari.test')
    print(f"\n[OK] Chef exists: {chef.uid}")
    print(f"     Email: {chef.email}")
    print(f"     Verified: {chef.email_verified}")
except Exception as e:
    print(f"[FAIL] Chef: {e}")

# Try Firebase REST API login
print("\n=== TESTING REST API LOGIN ===\n")

# Get API key from environment variable or firebase_options.dart
# ⚠️ NEVER hardcode API keys in code!
import os
API_KEY = os.getenv('FIREBASE_WEB_API_KEY', 'YOUR_API_KEY_HERE')

if API_KEY == 'YOUR_API_KEY_HERE':
    print("[WARNING] No API key configured. Set FIREBASE_WEB_API_KEY environment variable.")
    print("Skipping REST API login test.\n")
else:
    def test_login(email, password):
        url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
        try:
            r = requests.post(url, json={
                "email": email,
                "password": password,
                "returnSecureToken": True
            }, timeout=15)
            if r.status_code == 200:
                data = r.json()
                print(f"[OK] Login successful!")
                print(f"     Token: {data.get('idToken', 'N/A')[:50]}...")
                return True
            else:
                print(f"[FAIL] Status {r.status_code}")
                print(f"     Error: {r.json()}")
                return False
        except Exception as e:
            print(f"[FAIL] {e}")
            return False

    print("Testing customer login...")
    test_login('testcustomer@diari.test', 'Customer123!')
    
    print("\nTesting chef login...")
    test_login('testchef@diari.test', 'Chef123!')
test_login("testcustomer@diari.test", "test123456")

print("\nTesting chef login...")
test_login("testchef@diari.test", "test123456")

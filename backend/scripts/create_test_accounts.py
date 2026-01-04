#!/usr/bin/env python3
"""Create test accounts for comprehensive testing"""
import firebase_admin
from firebase_admin import credentials, firestore, auth

# Initialize Firebase (if not already initialized)
try:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
except:
    pass  # Already initialized

db = firestore.client()

print("=" * 60)
print("DIARI TEST ACCOUNT SETUP")
print("=" * 60)

# Create test customer account
test_customer_email = "testcustomer@diari.test"
test_customer_password = "test123456"

# Create test chef account
test_chef_email = "testchef@diari.test"
test_chef_password = "test123456"

print("\n📋 Creating Test Accounts...")

try:
    # Delete existing test accounts if they exist
    try:
        existing = auth.get_user_by_email(test_customer_email)
        auth.delete_user(existing.uid)
        print(f"  Deleted existing customer: {existing.uid}")
    except:
        pass

    try:
        existing = auth.get_user_by_email(test_chef_email)
        # Also delete from cookers collection
        db.collection('cookers').document(existing.uid).delete()
        auth.delete_user(existing.uid)
        print(f"  Deleted existing chef: {existing.uid}")
    except:
        pass

    # Create fresh test customer
    customer = auth.create_user(
        email=test_customer_email,
        password=test_customer_password,
        display_name="Test Customer",
        email_verified=True
    )
    print(f"\n✅ Created Test Customer:")
    print(f"   Email: {test_customer_email}")
    print(f"   Password: {test_customer_password}")
    print(f"   UID: {customer.uid}")

    # Create fresh test chef
    chef = auth.create_user(
        email=test_chef_email,
        password=test_chef_password,
        display_name="Test Chef",
        email_verified=True
    )
    
    # Register chef in cookers collection
    db.collection('cookers').document(chef.uid).set({
        'userId': chef.uid,
        'fullName': 'Test Chef',
        'name': 'Test Chef',
        'phone': '+216 12 345 678',
        'email': test_chef_email,
        'location': 'Tunis',
        'specialty': 'Tunisian Cuisine',
        'bio': 'Test chef for automated testing',
        'rating': 4.5,
        'reviewsCount': 10,
        'ordersCount': 25,
        'isAvailable': True,
        'image': '',
        'createdAt': firestore.SERVER_TIMESTAMP,
    })
    
    print(f"\n✅ Created Test Chef:")
    print(f"   Email: {test_chef_email}")
    print(f"   Password: {test_chef_password}")
    print(f"   UID: {chef.uid}")
    
    # Create a test dish for the chef
    dish_ref = db.collection('dishes').document()
    dish_ref.set({
        'name': 'Test Dish',
        'nameAr': 'طبق اختبار',
        'description': 'A delicious test dish for automated testing',
        'price': 15.00,
        'category': 'traditional',
        'image': '',
        'cookerId': chef.uid,
        'cookerName': 'Test Chef',
        'rating': 4.5,
        'reviewCount': 5,
        'prepTime': 30,
        'servings': 2,
        'isAvailable': True,
        'isPopular': False,
        'tags': ['test', 'traditional'],
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    })
    print(f"\n✅ Created Test Dish: {dish_ref.id}")
    print(f"   Name: Test Dish (طبق اختبار)")
    print(f"   Chef ID: {chef.uid}")

except Exception as e:
    print(f"\n❌ Error: {e}")

print("\n" + "=" * 60)
print("TEST ACCOUNTS READY!")
print("=" * 60)
print("\n🧪 Testing Workflow:")
print("1. Login as Customer: testcustomer@diari.test / test123456")
print("2. Add 'Test Dish (طبق اختبار)' to cart")
print("3. Place order")
print("4. Login as Chef: testchef@diari.test / test123456")
print("5. Check Orders tab - should see the order!")
print("=" * 60)

#!/usr/bin/env python3
"""Check Firestore data for debugging"""
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

print("=" * 60)
print("DIARI FIRESTORE DATA CHECK")
print("=" * 60)

# Check dishes
print("\n📋 DISHES:")
dishes = list(db.collection('dishes').stream())
print(f"Total dishes: {len(dishes)}")
for d in dishes:
    data = d.to_dict()
    print(f"  ID: {d.id}")
    print(f"    name: {data.get('name', 'N/A')}")
    print(f"    cookerId: {data.get('cookerId', 'MISSING!')}")
    print(f"    cookerName: {data.get('cookerName', 'N/A')}")
    print()

# Check orders
print("\n📦 ORDERS:")
orders = list(db.collection('orders').stream())
print(f"Total orders: {len(orders)}")
for o in orders:
    data = o.to_dict()
    print(f"  ID: {o.id}")
    print(f"    userId: {data.get('userId', 'N/A')}")
    print(f"    chefId: {data.get('chefId', 'MISSING!')}")
    print(f"    cookerId: {data.get('cookerId', 'MISSING!')}")
    print(f"    status: {data.get('status', 'N/A')}")
    print()

# Check cookers
print("\n👨‍🍳 COOKERS:")
cookers = list(db.collection('cookers').stream())
print(f"Total cookers: {len(cookers)}")
for c in cookers:
    data = c.to_dict()
    print(f"  ID: {c.id}")
    print(f"    name: {data.get('fullName', data.get('name', 'N/A'))}")
    print(f"    phone: {data.get('phone', 'N/A')}")
    print()

print("=" * 60)

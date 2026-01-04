#!/usr/bin/env python3
"""Clean up test orders and prepare for fresh testing"""
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

print("=" * 60)
print("CLEANING UP TEST ORDERS")
print("=" * 60)

# Delete orders that don't have a proper chefId
orders = list(db.collection('orders').stream())
deleted_count = 0

for o in orders:
    data = o.to_dict()
    chef_id = data.get('chefId')
    # Delete orders without proper chefId or in cancelled/pending status
    if not chef_id or chef_id == '' or data.get('status') in ['cancelled']:
        print(f"Deleting order {o.id} (chefId: {chef_id}, status: {data.get('status')})")
        db.collection('orders').document(o.id).delete()
        deleted_count += 1

print(f"\nDeleted {deleted_count} invalid/cancelled orders")

# Now check remaining orders
remaining = list(db.collection('orders').stream())
print(f"Remaining orders: {len(remaining)}")
for o in remaining:
    data = o.to_dict()
    print(f"  {o.id}: chefId={data.get('chefId')}, status={data.get('status')}")

print("\n" + "=" * 60)
print("CLEANUP COMPLETE")
print("=" * 60)

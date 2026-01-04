from app.services.firebase_service import init_firebase, get_db

init_firebase()
db = get_db()

print("=== FIRESTORE VERIFICATION ===\n")

# Check all collections
collections = ['dishes', 'cookers', 'orders', 'users', 'conversations', 'reviews', 'carts']

for coll_name in collections:
    try:
        docs = list(db.collection(coll_name).stream())
        count = len(docs)
        
        if coll_name == 'dishes' and docs:
            d = docs[0].to_dict()
            print(f"✓ {coll_name}: {count} documents - Sample: {d.get('name')} (ID: {docs[0].id})")
        elif coll_name == 'carts' and docs:
            c = docs[0].to_dict()
            items = c.get('items', [])
            if items:
                item = items[0]
                print(f"✓ {coll_name}: {count} documents - Sample item: dishId={item.get('dishId')}, cookerId={item.get('cookerId')}")
            else:
                print(f"✓ {coll_name}: {count} documents (empty items)")
        else:
            print(f"✓ {coll_name}: {count} documents")
    except Exception as e:
        print(f"✗ {coll_name}: ERROR - {e}")

print("\n=== DONE ===")

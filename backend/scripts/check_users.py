from app.services.firebase_service import init_firebase, get_db

init_firebase()
db = get_db()

print("=== USERS IN FIRESTORE ===")
users = list(db.collection('users').stream())
for u in users:
    data = u.to_dict()
    print(f"  ID: {u.id}")
    print(f"     Email: {data.get('email', 'N/A')}")
    print(f"     Name: {data.get('name', 'N/A')}")
    print(f"     Role: {data.get('role', 'N/A')}")
    print()

print(f"Total: {len(users)} users")

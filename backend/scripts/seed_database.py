"""
Seed Firestore Database
========================
Populates Firestore with Tunisian dishes and cookers data
Run once: python seed_database.py
"""

import os
from datetime import datetime
from app.services.firebase_service import init_firebase, get_db

# Tunisian Dishes Data
DISHES = [
    {
        'name': 'Couscous Royal',
        'nameAr': 'كسكسي ملكي',
        'description': 'كسكسي تونسي تقليدي مع لحم الضاني والخضروات الطازجة',
        'price': 18.5,
        'category': 'أطباق رئيسية',
        'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe',
        'cookerId': 'cook1',
        'cookerName': 'فاطمة الزهراء',
        'rating': 4.8,
        'reviewCount': 156,
        'prepTime': 45,
        'servings': 4,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['حلال', 'صحي', 'تقليدي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Brik à l\'oeuf',
        'nameAr': 'بريك بالبيض',
        'description': 'بريك تونسي مقرمش مع بيض وتونة',
        'price': 3.5,
        'category': 'مقبلات',
        'image': 'https://images.unsplash.com/photo-1619221882153-21e8f6ca3205',
        'cookerId': 'cook2',
        'cookerName': 'سامية بن عمر',
        'rating': 4.9,
        'reviewCount': 243,
        'prepTime': 15,
        'servings': 1,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['مقرمش', 'سريع'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Lablabi',
        'nameAr': 'لبلابي',
        'description': 'حساء حمص تونسي ساخن مع البيض والهريسة',
        'price': 4.0,
        'category': 'شوربة',
        'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd',
        'cookerId': 'cook3',
        'cookerName': 'نجلاء الصغيري',
        'rating': 4.7,
        'reviewCount': 189,
        'prepTime': 30,
        'servings': 2,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['نباتي', 'شتوي', 'صحي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Tajine Malsouka',
        'nameAr': 'طاجين المالسوقة',
        'description': 'طاجين تونسي مع المالسوقة والجبن والدجاج',
        'price': 12.0,
        'category': 'أطباق رئيسية',
        'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        'cookerId': 'cook1',
        'cookerName': 'فاطمة الزهراء',
        'rating': 4.6,
        'reviewCount': 98,
        'prepTime': 40,
        'servings': 6,
        'isAvailable': True,
        'isPopular': False,
        'tags': ['حلال', 'عائلي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Kamounia',
        'nameAr': 'كمونية',
        'description': 'كمونية لحم بقري مع الكمون والفلفل الحار',
        'price': 15.0,
        'category': 'أطباق رئيسية',
        'image': 'https://images.unsplash.com/photo-1574484284002-952d92456975',
        'cookerId': 'cook4',
        'cookerName': 'ليلى التونسي',
        'rating': 4.5,
        'reviewCount': 76,
        'prepTime': 60,
        'servings': 4,
        'isAvailable': True,
        'isPopular': False,
        'tags': ['حار', 'حلال'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Makroudh',
        'nameAr': 'مقروض',
        'description': 'حلوى تونسية تقليدية بالتمر والعسل',
        'price': 8.0,
        'category': 'حلويات',
        'image': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35',
        'cookerId': 'cook5',
        'cookerName': 'هدى المالكي',
        'rating': 4.9,
        'reviewCount': 312,
        'prepTime': 90,
        'servings': 12,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['حلو', 'تقليدي', 'مناسبات'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Ojja',
        'nameAr': 'عجة',
        'description': 'عجة تونسية مع الطماطم والفلفل والمرقاز',
        'price': 7.5,
        'category': 'أطباق رئيسية',
        'image': 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7',
        'cookerId': 'cook2',
        'cookerName': 'سامية بن عمر',
        'rating': 4.4,
        'reviewCount': 67,
        'prepTime': 25,
        'servings': 2,
        'isAvailable': True,
        'isPopular': False,
        'tags': ['سريع', 'حار'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Mechouia',
        'nameAr': 'مشوية',
        'description': 'سلطة خضروات مشوية تونسية مع الطماطم والفلفل',
        'price': 5.0,
        'category': 'سلطات',
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        'cookerId': 'cook3',
        'cookerName': 'نجلاء الصغيري',
        'rating': 4.7,
        'reviewCount': 134,
        'prepTime': 35,
        'servings': 3,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['نباتي', 'صحي', 'مشوي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Fricassé',
        'nameAr': 'فريكاسي',
        'description': 'فريكاسي تونسي مقلي مع تونة، زيتون، وهريسة',
        'price': 3.0,
        'category': 'مقبلات',
        'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff',
        'cookerId': 'cook2',
        'cookerName': 'سامية بن عمر',
        'rating': 4.8,
        'reviewCount': 267,
        'prepTime': 20,
        'servings': 1,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['سريع', 'مقرمش'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Bambalouni',
        'nameAr': 'بمبلوني',
        'description': 'دونات تونسية مقلية محلاة بالسكر',
        'price': 2.0,
        'category': 'حلويات',
        'image': 'https://images.unsplash.com/photo-1551024601-bec78aea704b',
        'cookerId': 'cook5',
        'cookerName': 'هدى المالكي',
        'rating': 4.6,
        'reviewCount': 198,
        'prepTime': 30,
        'servings': 6,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['حلو', 'سريع'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Kafteji',
        'nameAr': 'كفتاجي',
        'description': 'مزيج خضروات مقلية مع بيض وتونة',
        'price': 6.5,
        'category': 'مقبلات',
        'image': 'https://images.unsplash.com/photo-1598511726623-d2e9996892f0',
        'cookerId': 'cook4',
        'cookerName': 'ليلى التونسي',
        'rating': 4.3,
        'reviewCount': 54,
        'prepTime': 35,
        'servings': 2,
        'isAvailable': True,
        'isPopular': False,
        'tags': ['صحي', 'محلي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Mlou7ia',
        'nameAr': 'ملوخية',
        'description': 'ملوخية تونسية مع لحم البقر والخبز المحمص',
        'price': 11.0,
        'category': 'أطباق رئيسية',
        'image': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445',
        'cookerId': 'cook1',
        'cookerName': 'فاطمة الزهراء',
        'rating': 4.5,
        'reviewCount': 89,
        'prepTime': 50,
        'servings': 4,
        'isAvailable': True,
        'isPopular': False,
        'tags': ['حلال', 'تقليدي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Chorba Frik',
        'nameAr': 'شربة فريك',
        'description': 'شوربة فريك تونسية مع لحم الضاني',
        'price': 8.5,
        'category': 'شوربة',
        'image': 'https://images.unsplash.com/photo-1547592180-85f173990554',
        'cookerId': 'cook3',
        'cookerName': 'نجلاء الصغيري',
        'rating': 4.7,
        'reviewCount': 143,
        'prepTime': 45,
        'servings': 4,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['شتوي', 'صحي', 'حلال'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Assida Zgougou',
        'nameAr': 'عصيدة الزقوقو',
        'description': 'حلوى تونسية تقليدية بالصنوبر الحلبي',
        'price': 7.0,
        'category': 'حلويات',
        'image': 'https://images.unsplash.com/photo-1563805042-7684c019e1cb',
        'cookerId': 'cook5',
        'cookerName': 'هدى المالكي',
        'rating': 4.8,
        'reviewCount': 176,
        'prepTime': 60,
        'servings': 8,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['حلو', 'تقليدي', 'مناسبات'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Salade Tunisienne',
        'nameAr': 'سلطة تونسية',
        'description': 'سلطة طماطم وفلفل حار مع التونة والبيض',
        'price': 4.5,
        'category': 'سلطات',
        'image': 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe',
        'cookerId': 'cook3',
        'cookerName': 'نجلاء الصغيري',
        'rating': 4.6,
        'reviewCount': 112,
        'prepTime': 15,
        'servings': 2,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['صحي', 'سريع', 'نباتي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Mloukhia',
        'nameAr': 'ملوخية بالدجاج',
        'description': 'ملوخية مع الدجاج والبصل',
        'price': 10.0,
        'category': 'أطباق رئيسية',
        'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
        'cookerId': 'cook4',
        'cookerName': 'ليلى التونسي',
        'rating': 4.4,
        'reviewCount': 71,
        'prepTime': 55,
        'servings': 4,
        'isAvailable': True,
        'isPopular': False,
        'tags': ['حلال', 'تقليدي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Merguez',
        'nameAr': 'مرقاز',
        'description': 'سجق تونسي حار مع الهريسة',
        'price': 9.0,
        'category': 'مقبلات',
        'image': 'https://images.unsplash.com/photo-1529042410759-befb1204b468',
        'cookerId': 'cook2',
        'cookerName': 'سامية بن عمر',
        'rating': 4.7,
        'reviewCount': 156,
        'prepTime': 25,
        'servings': 3,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['حار', 'حلال', 'مشوي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Baklawa',
        'nameAr': 'بقلاوة',
        'description': 'بقلاوة تونسية بالفستق والعسل',
        'price': 12.0,
        'category': 'حلويات',
        'image': 'https://images.unsplash.com/photo-1519676867240-f03562e64548',
        'cookerId': 'cook5',
        'cookerName': 'هدى المالكي',
        'rating': 4.9,
        'reviewCount': 289,
        'prepTime': 120,
        'servings': 16,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['حلو', 'فاخر', 'مناسبات'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Slata Mechouia',
        'nameAr': 'سلاطة مشوية',
        'description': 'سلطة خضروات مشوية مع زيت الزيتون',
        'price': 5.5,
        'category': 'سلطات',
        'image': 'https://images.unsplash.com/photo-1546793665-c74683f339c1',
        'cookerId': 'cook1',
        'cookerName': 'فاطمة الزهراء',
        'rating': 4.5,
        'reviewCount': 98,
        'prepTime': 40,
        'servings': 3,
        'isAvailable': True,
        'isPopular': False,
        'tags': ['نباتي', 'صحي'],
        'createdAt': datetime.now()
    },
    {
        'name': 'Yo-Yo',
        'nameAr': 'يويو',
        'description': 'بسكويت تونسي محشو بالمربى',
        'price': 6.0,
        'category': 'حلويات',
        'image': 'https://images.unsplash.com/photo-1486427944299-d1955d23e34d',
        'cookerId': 'cook5',
        'cookerName': 'هدى المالكي',
        'rating': 4.6,
        'reviewCount': 124,
        'prepTime': 45,
        'servings': 12,
        'isAvailable': True,
        'isPopular': True,
        'tags': ['حلو', 'بسكويت'],
        'createdAt': datetime.now()
    },
]

# Cookers Data
COOKERS = [
    {
        'id': 'cook1',
        'name': 'فاطمة الزهراء',
        'bio': 'طباخة تونسية متخصصة في الأطباق التقليدية مع 20 سنة خبرة',
        'specialty': 'كسكسي وأطباق تقليدية',
        'rating': 4.8,
        'reviewCount': 345,
        'dishCount': 12,
        'location': 'تونس العاصمة',
        'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
        'isVerified': True,
        'isActive': True,
        'joinedDate': datetime.now(),
        'tags': ['تقليدي', 'عائلي', 'حلال'],
        'phone': '+216 20 123 456',
        'deliveryFee': 2.0,
        'minOrder': 10.0,
    },
    {
        'id': 'cook2',
        'name': 'سامية بن عمر',
        'bio': 'متخصصة في المقبلات التونسية والأكلات السريعة',
        'specialty': 'بريك وفريكاسي',
        'rating': 4.9,
        'reviewCount': 567,
        'dishCount': 8,
        'location': 'صفاقس',
        'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        'isVerified': True,
        'isActive': True,
        'joinedDate': datetime.now(),
        'tags': ['سريع', 'مقبلات', 'محلي'],
        'phone': '+216 22 234 567',
        'deliveryFee': 1.5,
        'minOrder': 5.0,
    },
    {
        'id': 'cook3',
        'name': 'نجلاء الصغيري',
        'bio': 'خبيرة في الشوربات والسلطات الصحية',
        'specialty': 'لبلابي وسلطات',
        'rating': 4.7,
        'reviewCount': 423,
        'dishCount': 10,
        'location': 'سوسة',
        'image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        'isVerified': True,
        'isActive': True,
        'joinedDate': datetime.now(),
        'tags': ['صحي', 'نباتي', 'شوربة'],
        'phone': '+216 24 345 678',
        'deliveryFee': 2.5,
        'minOrder': 8.0,
    },
    {
        'id': 'cook4',
        'name': 'ليلى التونسي',
        'bio': 'طباخة محترفة متخصصة في الأطباق الحارة',
        'specialty': 'كمونية وأطباق حارة',
        'rating': 4.5,
        'reviewCount': 234,
        'dishCount': 7,
        'location': 'المنستير',
        'image': 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f',
        'isVerified': True,
        'isActive': True,
        'joinedDate': datetime.now(),
        'tags': ['حار', 'تقليدي'],
        'phone': '+216 26 456 789',
        'deliveryFee': 3.0,
        'minOrder': 12.0,
    },
    {
        'id': 'cook5',
        'name': 'هدى المالكي',
        'bio': 'متخصصة في الحلويات التونسية التقليدية',
        'specialty': 'مقروض وبقلاوة',
        'rating': 4.9,
        'reviewCount': 789,
        'dishCount': 15,
        'location': 'قابس',
        'image': 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91',
        'isVerified': True,
        'isActive': True,
        'joinedDate': datetime.now(),
        'tags': ['حلويات', 'تقليدي', 'فاخر'],
        'phone': '+216 28 567 890',
        'deliveryFee': 2.0,
        'minOrder': 15.0,
    },
]


def seed_database():
    """Seed Firestore with dishes and cookers"""
    print("🌱 Starting database seed...")
    
    # Initialize Firebase
    init_firebase()
    db = get_db()
    
    if db is None:
        print("❌ Failed to initialize Firebase")
        return
    
    print("✅ Firebase initialized")
    
    # Seed cookers first
    print(f"\n📝 Seeding {len(COOKERS)} cookers...")
    cookers_ref = db.collection('cookers')
    
    for cooker in COOKERS:
        doc_ref = cookers_ref.document(cooker['id'])
        doc_ref.set(cooker)
        print(f"   ✓ Added: {cooker['name']}")
    
    print(f"✅ {len(COOKERS)} cookers added")
    
    # Seed dishes
    print(f"\n📝 Seeding {len(DISHES)} dishes...")
    dishes_ref = db.collection('dishes')
    
    for dish in DISHES:
        doc_ref = dishes_ref.add(dish)
        print(f"   ✓ Added: {dish['nameAr']} ({dish['price']} DT)")
    
    print(f"✅ {len(DISHES)} dishes added")
    
    print("\n🎉 Database seeded successfully!")
    print(f"   - {len(COOKERS)} cookers")
    print(f"   - {len(DISHES)} dishes")
    print("\n📊 Categories:")
    categories = set(dish['category'] for dish in DISHES)
    for cat in categories:
        count = sum(1 for d in DISHES if d['category'] == cat)
        print(f"   - {cat}: {count} dishes")


if __name__ == '__main__':
    seed_database()

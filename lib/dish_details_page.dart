import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/dish.dart';
import 'theme.dart';
import 'services/enhanced_cart_service.dart';
import 'services/user_service.dart';
import 'services/review_service.dart';
import 'services/dish_service.dart' as dish_svc;

const Color _primary = AppColors.primary;
const Color _backgroundLight = AppColors.backgroundLight;

class DishDetailsPage extends StatefulWidget {
  final Dish dish;
  final String? dishId;
  
  const DishDetailsPage({super.key, required this.dish, this.dishId});

  @override
  State<DishDetailsPage> createState() => _DishDetailsPageState();
}

class _DishDetailsPageState extends State<DishDetailsPage> {
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  dish_svc.Dish? _firestoreDish; // Store Firestore dish for cookerId

  @override
  void initState() {
    super.initState();
    _loadDishData();
    _checkIfFavorite();
    _loadReviews();
  }

  Future<void> _loadDishData() async {
    // If dishId is provided, fetch from Firestore to get cookerId
    if (widget.dishId != null) {
      final dish = await dish_svc.DishService.getDishById(widget.dishId!);
      if (dish != null && mounted) {
        setState(() {
          _firestoreDish = dish;
        });
      }
    }
  }

  Future<void> _checkIfFavorite() async {
    setState(() => _isCheckingFavorite = true);
    final response = await UserService.getFavorites();
    if (response.success && response.data != null) {
      final List<dynamic> favList = response.data!['favorites'] ?? [];
      final dishId = widget.dishId ?? widget.dish.name;
      setState(() {
        _isFavorite = favList.any((fav) => fav['dishId'] == dishId);
        _isCheckingFavorite = false;
      });
    } else {
      setState(() => _isCheckingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final dishId = widget.dishId ?? widget.dish.name;
    
    if (_isFavorite) {
      final response = await UserService.removeFavorite(dishId);
      if (response.success && mounted) {
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الإزالة من المفضلة'), backgroundColor: Colors.grey),
        );
      }
    } else {
      final response = await UserService.addFavorite(
        dishId: dishId,
        dishName: widget.dish.name,
        dishImage: widget.dish.imageAsset,
      );
      if (response.success && mounted) {
        setState(() => _isFavorite = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الإضافة إلى المفضلة'), backgroundColor: _primary),
        );
      }
    }
  }

  void _messageChef() {
    if (_firestoreDish == null || _firestoreDish!.cookerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن التواصل مع الطباخ حالياً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to CookerMessagesPage with chef info
    Navigator.pushNamed(
      context,
      '/cooker-messages',
      arguments: {
        'cookerId': _firestoreDish!.cookerId,
        'cookerName': widget.dish.cookName,
      },
    );
  }

  Future<void> _loadReviews() async {
    final dishId = widget.dishId ?? _firestoreDish?.id ?? widget.dish.name;
    setState(() => _isLoadingReviews = true);
    
    try {
      // Load directly from Firestore (more reliable)
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('dishId', isEqualTo: dishId)
          .limit(10)
          .get();
      
      if (mounted) {
        final reviews = reviewsSnapshot.docs.map((doc) {
          final data = doc.data();
          return Review(
            id: doc.id,
            rating: data['rating'] ?? 0,
            comment: data['comment'] ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
            userName: data['userName'] ?? 'مستخدم',
            userImage: data['userImage'] ?? '',
          );
        }).toList();
        
        // Sort by date (newest first)
        reviews.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews from Firestore: $e');
      if (mounted) {
        setState(() {
          _reviews = [];
          _isLoadingReviews = false;
        });
      }
    }
  }

  void _showAddReviewDialog() {
    int rating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('أضف تقييمك', textAlign: TextAlign.right),
          content: StatefulBuilder(
            builder: (context, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => IconButton(
                    iconSize: 36,
                    onPressed: () => setModalState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  )),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'اكتب تعليقك هنا...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (rating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء اختيار تقييم')),
                  );
                  return;
                }

                Navigator.pop(ctx); // Close dialog immediately
                
                try {
                  final dishId = widget.dishId ?? _firestoreDish?.id ?? widget.dish.name;
                  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
                  
                  // Get user info
                  String userName = 'مستخدم';
                  String userImage = '';
                  
                  try {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get();
                    if (userDoc.exists) {
                      final userData = userDoc.data()!;
                      userName = userData['name'] ?? 'مستخدم';
                      userImage = userData['profileImage'] ?? '';
                    }
                  } catch (e) {
                    debugPrint('Error getting user info: $e');
                  }
                  
                  // Save review directly to Firestore
                  await FirebaseFirestore.instance.collection('reviews').add({
                    'dishId': dishId,
                    'userId': userId,
                    'userName': userName,
                    'userImage': userImage,
                    'rating': rating,
                    'comment': commentController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  // Update dish rating
                  final reviewsSnapshot = await FirebaseFirestore.instance
                      .collection('reviews')
                      .where('dishId', isEqualTo: dishId)
                      .get();
                  
                  final ratings = reviewsSnapshot.docs
                      .map((doc) => (doc.data()['rating'] ?? 0) as int)
                      .toList();
                  
                  if (ratings.isNotEmpty) {
                    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
                    await FirebaseFirestore.instance
                        .collection('dishes')
                        .doc(dishId)
                        .update({
                      'rating': double.parse(avgRating.toStringAsFixed(1)),
                      'reviewCount': ratings.length,
                    });
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إضافة التقييم بنجاح'), backgroundColor: _primary),
                    );
                    _loadReviews(); // Reload reviews
                  }
                } catch (e) {
                  debugPrint('Error adding review: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  void _incrementQuantity() {
    setState(() {
      if (_quantity < 10) _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) _quantity--;
    });
  }

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);
    
    // Use cookerId from: 1) Firestore dish, 2) widget.dish.cookerId, 3) fallback to cookName
    final cookerId = _firestoreDish?.cookerId ?? 
                     (widget.dish.cookerId.isNotEmpty ? widget.dish.cookerId : widget.dish.cookName);
    final cookerName = _firestoreDish?.cookerName ?? widget.dish.cookName;
    
    print('AddToCart: dishId=${widget.dishId ?? widget.dish.name}, cookerId=$cookerId, cookerName=$cookerName');
    print('AddToCart: _firestoreDish=${_firestoreDish != null ? "loaded" : "null"}, firestoreCookerId=${_firestoreDish?.cookerId}');
    print('AddToCart: widget.dish.cookerId=${widget.dish.cookerId}');
    
    final success = await CartService.addItem(
      dishId: widget.dishId ?? widget.dish.name,
      dishName: widget.dish.name,
      price: _extractPrice(widget.dish.price),
      image: widget.dish.imageAsset,
      cookerId: cookerId,
      cookerName: cookerName,
      quantity: _quantity,
    );
    
    setState(() => _isAddingToCart = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت الإضافة إلى السلة ($_quantity ${widget.dish.name})'),
          backgroundColor: _primary,
          action: SnackBarAction(
            label: 'عرض السلة',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل إضافة الطبق. تأكد من تسجيل الدخول.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _extractPrice(String priceStr) {
    // Extract number from price string like "2.00 د.ت" or "15.50 دت"
    // First, try to find a decimal number pattern
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(priceStr);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundLight,
        appBar: AppBar(
          backgroundColor: _primary,
          elevation: 0,
          centerTitle: true,
          title: const Text('تفاصيل الطبق', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!_isCheckingFavorite)
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
                tooltip: _isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
              ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.dish.imageAsset.startsWith('http')
                          ? Image.network(widget.dish.imageAsset, height: 220, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 220,
                                color: Colors.grey[300],
                                child: const Icon(Icons.restaurant, size: 60),
                              ))
                          : Image.asset(widget.dish.imageAsset, height: 220, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 220,
                                color: Colors.grey[300],
                                child: const Icon(Icons.restaurant, size: 60),
                              )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(widget.dish.name, textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(widget.dish.price, textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primary)),
                        const SizedBox(height: 4),
                        Text('من اعداد ${widget.dish.cookName}', textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Message Chef Button
                            if (_firestoreDish?.cookerId != null)
                              OutlinedButton.icon(
                                onPressed: () => _messageChef(),
                                icon: const Icon(Icons.message_outlined, size: 18),
                                label: const Text('راسل الطباخ'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primary,
                                  side: const BorderSide(color: _primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            // Rating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.star, size: 20, color: _primary),
                                const SizedBox(width: 4),
                                Text(widget.dish.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Reviews Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _showAddReviewDialog,
                              icon: const Icon(Icons.add, color: _primary),
                              label: const Text('أضف تقييم', style: TextStyle(color: _primary)),
                            ),
                            const Text('التقييمات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingReviews)
                          const Center(child: CircularProgressIndicator())
                        else if (_reviews.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('لا توجد تقييمات بعد. كن أول من يقيّم!', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          ..._reviews.map((review) => _buildReviewCard(review)).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _decrementQuantity,
                          ),
                          Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _incrementQuantity,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAddingToCart ? null : _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isAddingToCart
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('أضف للسلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.amber,
                )),
              ),
              Row(
                children: [
                  if (review.userImage.isNotEmpty)
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(review.userImage),
                    )
                  else
                    const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person, size: 16),
                    ),
                  const SizedBox(width: 8),
                  Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment, textAlign: TextAlign.right, style: const TextStyle(color: Colors.black87)),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDate(review.createdAt!),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).floor()} أسابيع';
    if (diff.inDays < 365) return 'منذ ${(diff.inDays / 30).floor()} أشهر';
    return 'منذ ${(diff.inDays / 365).floor()} سنة';
  }
}

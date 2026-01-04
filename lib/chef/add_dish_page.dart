import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import '../theme.dart';
import '../services/chef_dish_service.dart';
import '../services/api_service.dart';
import '../services/image_service.dart';

const Color _primary = AppColors.primary;

class AddDishPage extends StatefulWidget {
  final ChefDish? dish; // For editing existing dish
  
  const AddDishPage({super.key, this.dish});

  @override
  State<AddDishPage> createState() => _AddDishPageState();
}

class _AddDishPageState extends State<AddDishPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _servingSizeController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedCategory = 'traditional';
  bool _isSpicy = false;
  bool _isVegetarian = false;
  String _imageUrl = '';
  Uint8List? _imageBytes;
  bool _isUploadingImage = false;

  bool get isEditing => widget.dish != null;

  final List<Map<String, String>> _categories = [
    {'id': 'seafood', 'name': 'بحري', 'icon': '🦐'},
    {'id': 'couscous', 'name': 'كسكسي', 'icon': '🍲'},
    {'id': 'pasta', 'name': 'مقرونة', 'icon': '🍝'},
    {'id': 'traditional', 'name': 'تقليدي', 'icon': '🥘'},
    {'id': 'grilled', 'name': 'مشوي', 'icon': '🍖'},
    {'id': 'salads', 'name': 'سلطات', 'icon': '🥗'},
    {'id': 'desserts', 'name': 'حلويات', 'icon': '🍰'},
    {'id': 'drinks', 'name': 'مشروبات', 'icon': '🥤'},
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final dish = widget.dish!;
    _nameController.text = dish.name;
    _descriptionController.text = dish.description;
    _priceController.text = dish.price.toString();
    _ingredientsController.text = dish.ingredients.join(', ');
    _prepTimeController.text = dish.preparationTime.toString();
    _servingSizeController.text = dish.servingSize;
    _selectedCategory = dish.category;
    _isSpicy = dish.isSpicy;
    _isVegetarian = dish.isVegetarian;
    _imageUrl = dish.image;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _ingredientsController.dispose();
    _prepTimeController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('يجب تسجيل الدخول');
        return;
      }

      final ingredients = _ingredientsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Upload image if we have bytes
      String finalImageUrl = _imageUrl;
      if (_imageBytes != null) {
        setState(() => _isUploadingImage = true);
        try {
          // Show a snackbar to indicate upload is starting
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('جاري رفع الصورة...'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          }
          
          final uploadedUrl = await ImageService.uploadDishImage(
            imageBytes: _imageBytes!,
            chefId: user.uid,
          );
          if (uploadedUrl != null) {
            finalImageUrl = uploadedUrl;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم رفع الصورة بنجاح ✓'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            _showError('فشل في رفع الصورة');
            return;
          }
        } catch (e) {
          _showError('خطأ في رفع الصورة: $e');
          return;
        } finally {
          setState(() => _isUploadingImage = false);
        }
      }

      final prepTime = int.tryParse(_prepTimeController.text) ?? 30;

      ApiResponse response;
      
      if (isEditing) {
        response = await ChefDishService.updateDish(
          userId: user.uid,
          dishId: widget.dish!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          category: _selectedCategory,
          image: finalImageUrl,
          ingredients: ingredients,
          preparationTime: prepTime,
          servingSize: _servingSizeController.text.trim(),
          isSpicy: _isSpicy,
          isVegetarian: _isVegetarian,
        );
      } else {
        response = await ChefDishService.createDish(
          userId: user.uid,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          category: _selectedCategory,
          image: finalImageUrl,
          ingredients: ingredients,
          preparationTime: prepTime,
          servingSize: _servingSizeController.text.isEmpty 
              ? '1 شخص' 
              : _servingSizeController.text.trim(),
          isSpicy: _isSpicy,
          isVegetarian: _isVegetarian,
        );
      }

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'تم تحديث الطبق بنجاح' : 'تمت إضافة الطبق بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError(response.error ?? 'حدث خطأ');
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: _primary,
          title: Text(isEditing ? 'تعديل الطبق' : 'إضافة طبق جديد'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Section
                GestureDetector(
                  onTap: _isUploadingImage ? null : _showImageDialog,
                  child: Stack(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          image: _imageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_imageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : _imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_imageBytes == null && _imageUrl.isEmpty)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'إضافة صورة الطبق',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              )
                            : Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                ),
                              ),
                      ),
                      if (_isUploadingImage)
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('اسم الطبق *', Icons.restaurant),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال اسم الطبق';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration('وصف الطبق', Icons.description),
                ),
                const SizedBox(height: 16),

                // Price Field
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('السعر (دينار) *', Icons.attach_money),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال السعر';
                    }
                    if (double.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category Selection
                const Text(
                  'التصنيف',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['id'];
                    return ChoiceChip(
                      label: Text('${cat['icon']} ${cat['name']}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat['id']!);
                        }
                      },
                      selectedColor: _primary.withOpacity(0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Ingredients Field
                TextFormField(
                  controller: _ingredientsController,
                  decoration: InputDecoration(
                    labelText: 'المكونات (مفصولة بفاصلة)',
                    hintText: 'لحم، بصل، طماطم، توابل...',
                    prefixIcon: const Icon(Icons.list_alt),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Prep Time & Serving Size Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prepTimeController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('وقت التحضير (دقيقة)', Icons.timer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _servingSizeController,
                        decoration: _inputDecoration('حجم الوجبة', Icons.people),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Options
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('حار 🌶️'),
                        value: _isSpicy,
                        onChanged: (value) => setState(() => _isSpicy = value!),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('نباتي 🥬'),
                        value: _isVegetarian,
                        onChanged: (value) => setState(() => _isVegetarian = value!),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEditing ? 'حفظ التغييرات' : 'إضافة الطبق',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  void _showImageDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر صورة الطبق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('اختيار من المعرض'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(fromCamera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('التقاط صورة'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.orange),
                title: const Text('إدخال رابط URL'),
                onTap: () {
                  Navigator.pop(context);
                  _showUrlDialog();
                },
              ),
              if (_imageBytes != null || _imageUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('إزالة الصورة'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageBytes = null;
                      _imageUrl = '';
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    setState(() => _isUploadingImage = true);
    try {
      final xFile = fromCamera
          ? await ImageService.pickFromCamera()
          : await ImageService.pickFromGallery();
      
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageUrl = ''; // Clear URL when picking local image
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في اختيار الصورة: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _showUrlDialog() {
    final urlController = TextEditingController(text: _imageUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة رابط صورة', textDirection: TextDirection.rtl),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            hintTextDirection: TextDirection.ltr,
          ),
          textDirection: TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _imageUrl = urlController.text.trim();
                _imageBytes = null; // Clear bytes when using URL
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/product_service.dart';
import '../../models/category_model.dart';

class AdminCategoriesScreen extends StatefulWidget {
  @override
  _AdminCategoriesScreenState createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  String _error = '';

  final _nameController = TextEditingController();
  File? _imageFile;
  String? _imageUrl;
  bool _isSaving = false;
  CategoryModel? _editingCategory;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final productService = Provider.of<ProductService>(
        context,
        listen: false,
      );
      final categories = await productService.getCategories();

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh mục: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'categories/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}',
      );

      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải lên hình ảnh: ${e.toString()}')),
      );
      return null;
    }
  }

  void _showCategoryDialog({CategoryModel? category}) {
    setState(() {
      _editingCategory = category;
      _nameController.text = category?.name ?? '';
      _imageUrl = category?.image;
      _imageFile = null;
    });

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  _editingCategory == null
                      ? 'Thêm danh mục'
                      : 'Chỉnh sửa danh mục',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên danh mục',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final pickedFile = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );

                          if (pickedFile != null) {
                            setState(() {
                              _imageFile = File(pickedFile.path);
                            });
                          }
                        },
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              _imageFile != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : _imageUrl != null && _imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : Center(
                                    child: Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _isSaving
                            ? null
                            : () async {
                              if (_nameController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Vui lòng nhập tên danh mục'),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _isSaving = true;
                              });

                              try {
                                final productService =
                                    Provider.of<ProductService>(
                                      context,
                                      listen: false,
                                    );

                                // Upload image if new file selected
                                String? imageUrl = _imageUrl;
                                if (_imageFile != null) {
                                  imageUrl = await _uploadImage();
                                  if (imageUrl == null) {
                                    throw Exception(
                                      'Không thể tải lên hình ảnh',
                                    );
                                  }
                                }

                                final category = CategoryModel(
                                  id: _editingCategory?.id ?? '',
                                  name: _nameController.text,
                                  image: imageUrl ?? '',
                                );

                                if (_editingCategory == null) {
                                  // Add new category
                                  await productService.addCategory(category);
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text('Thêm danh mục thành công'),
                                    ),
                                  );
                                } else {
                                  // Update existing category
                                  await productService.updateCategory(category);
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cập nhật danh mục thành công',
                                      ),
                                    ),
                                  );
                                }

                                Navigator.pop(context);
                                _loadCategories();
                              } catch (e) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: ${e.toString()}'),
                                  ),
                                );
                              } finally {
                                setState(() {
                                  _isSaving = false;
                                });
                              }
                            },
                    child:
                        _isSaving
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text('Lưu'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _deleteCategory(String categoryId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Xác nhận xóa'),
            content: Text('Bạn có chắc muốn xóa danh mục này?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  try {
                    final productService = Provider.of<ProductService>(
                      context,
                      listen: false,
                    );
                    await productService.deleteCategory(categoryId);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xóa danh mục thành công')),
                    );

                    _loadCategories();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Xóa'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý danh mục')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorWidget()
              : _buildCategoriesList(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showCategoryDialog(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadCategories, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (_categories.isEmpty) {
      return Center(child: Text('Chưa có danh mục nào'));
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          child: InkWell(
            onTap: () => _showCategoryDialog(category: category),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                // Category image
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Container(
                      width: double.infinity,
                      child:
                          category.image.isNotEmpty
                              ? Image.network(category.image, fit: BoxFit.cover)
                              : Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.category, size: 60),
                              ),
                    ),
                  ),
                ),

                // Category info
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed:
                                () => _showCategoryDialog(category: category),
                            tooltip: 'Chỉnh sửa',
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCategory(category.id),
                            tooltip: 'Xóa',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const EditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPercentageController = TextEditingController();

  List<String> _images = [];
  List<CategoryModel> _categories = [];
  List<String> _selectedCategories = [];
  List<Map<String, dynamic>> _variants = [];

  bool _isNew = false;
  bool _isTrending = false;
  bool _isOnSale = false;

  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _brandController.text = widget.product!.brand;
      _priceController.text = widget.product!.price.toString();
      _discountPercentageController.text =
          widget.product!.discountPercentage?.toString() ?? '';

      _images = List<String>.from(widget.product!.images);
      _selectedCategories = List<String>.from(widget.product!.categories);
      _variants =
          widget.product!.variants
              .map((variant) => {'name': variant.name, 'stock': variant.stock})
              .toList();

      _isNew = widget.product!.isNew;
      _isTrending = widget.product!.isTrending;
      _isOnSale = widget.product!.isOnSale;
    } else {
      // Add default variants for new product
      _variants = [
        {'name': 'Mặc định', 'stock': 0},
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _discountPercentageController.dispose();
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

  Future<void> _addImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        final file = File(pickedFile.path);
        final storageRef = FirebaseStorage.instance.ref().child(
          'products/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}',
        );

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _images.add(downloadUrl);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải lên hình ảnh: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _addVariant() {
    setState(() {
      _variants.add({'name': '', 'stock': 0});
    });
  }

  void _updateVariant(int index, String field, dynamic value) {
    setState(() {
      _variants[index][field] = value;
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng thêm ít nhất một hình ảnh')),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn ít nhất một danh mục')),
      );
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng thêm ít nhất một phiên bản')),
      );
      return;
    }

    // Check variant names
    for (var i = 0; i < _variants.length; i++) {
      if (_variants[i]['name'] == null ||
          _variants[i]['name'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tên phiên bản không được để trống')),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final productService = Provider.of<ProductService>(
        context,
        listen: false,
      );

      // Convert variants from Map to ProductVariant
      final variants =
          _variants
              .map(
                (variant) => ProductVariant(
                  name: variant['name'],
                  stock: variant['stock'],
                ),
              )
              .toList();

      // Create product object
      final product = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        brand: _brandController.text,
        price: double.parse(_priceController.text),
        discountPercentage:
            _discountPercentageController.text.isNotEmpty
                ? double.parse(_discountPercentageController.text)
                : null,
        categories: _selectedCategories,
        images: _images,
        variants: variants,
        ratings: widget.product?.ratings ?? ProductRating(average: 0, count: 0),
        isNew: _isNew,
        isTrending: _isTrending,
        isOnSale: _isOnSale,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      if (widget.product == null) {
        // Add new product
        await productService.addProduct(product);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thêm sản phẩm thành công')));
      } else {
        // Update existing product
        await productService.updateProduct(product);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cập nhật sản phẩm thành công')));
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm',
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorWidget()
              : _buildForm(),
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Product images
          Text(
            'Hình ảnh sản phẩm',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Container(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Add image button
                InkWell(
                  onTap: _isSaving ? null : _addImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child:
                          _isSaving
                              ? CircularProgressIndicator()
                              : Icon(Icons.add_photo_alternate, size: 40),
                    ),
                  ),
                ),

                // Existing images
                ..._images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final imageUrl = entry.value;

                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 8,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Product details
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Tên sản phẩm',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập tên sản phẩm';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _brandController,
            decoration: InputDecoration(
              labelText: 'Thương hiệu',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập thương hiệu';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Giá (VNĐ)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập giá';
                    }

                    if (double.tryParse(value) == null) {
                      return 'Giá không hợp lệ';
                    }

                    if (double.parse(value) <= 0) {
                      return 'Giá phải lớn hơn 0';
                    }

                    return null;
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _discountPercentageController,
                  decoration: InputDecoration(
                    labelText: 'Giảm giá (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Giảm giá không hợp lệ';
                      }

                      final discount = double.parse(value);

                      if (discount < 0 || discount > 50) {
                        return 'Giảm giá phải từ 0-50%';
                      }
                    }

                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Mô tả sản phẩm',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mô tả sản phẩm';
              }

              if (value.split('\n').length < 5) {
                return 'Mô tả phải có ít nhất 5 dòng';
              }

              return null;
            },
          ),
          SizedBox(height: 16),

          // Categories
          Text(
            'Danh mục sản phẩm',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _categories.map((category) {
                  final isSelected = _selectedCategories.contains(category.id);

                  return FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category.id);
                        } else {
                          _selectedCategories.remove(category.id);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
          SizedBox(height: 16),

          // Variants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phiên bản sản phẩm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addVariant,
                icon: Icon(Icons.add),
                label: Text('Thêm'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _variants.length,
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue:
                              _variants[index]['name']?.toString() ?? '',
                          decoration: InputDecoration(
                            labelText: 'Tên',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            _updateVariant(index, 'name', value);
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue:
                              _variants[index]['stock']?.toString() ?? '0',
                          decoration: InputDecoration(
                            labelText: 'Số lượng',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateVariant(
                              index,
                              'stock',
                              int.tryParse(value) ?? 0,
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            _variants.length > 1
                                ? () => _removeVariant(index)
                                : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),

          // Featured flags
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: Text('Sản phẩm mới'),
                  value: _isNew,
                  onChanged: (value) {
                    setState(() {
                      _isNew = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: Text('Bán chạy'),
                  value: _isTrending,
                  onChanged: (value) {
                    setState(() {
                      _isTrending = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          CheckboxListTile(
            title: Text('Khuyến mãi'),
            value: _isOnSale,
            onChanged: (value) {
              setState(() {
                _isOnSale = value ?? false;

                // If marked as on sale, ensure there's a discount percentage
                if (_isOnSale &&
                    (_discountPercentageController.text.isEmpty ||
                        double.tryParse(_discountPercentageController.text) ==
                            0)) {
                  _discountPercentageController.text = '10';
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: 24),

          // Save button
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProduct,
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
                    : Text('Lưu sản phẩm'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

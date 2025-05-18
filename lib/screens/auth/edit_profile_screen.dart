import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();

  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.userModel != null) {
      final user = authService.userModel!;

      setState(() {
        _fullNameController.text = user.fullName;
        _addresses = List<Map<String, dynamic>>.from(user.addresses);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.updateProfile(
        _fullNameController.text.trim(),
        _addresses,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hồ sơ đã được cập nhật thành công')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi cập nhật hồ sơ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddAddressDialog({Map<String, dynamic>? address, int? index}) {
    final nameController = TextEditingController(text: address?['name'] ?? '');
    final phoneController = TextEditingController(
      text: address?['phone'] ?? '',
    );
    final streetController = TextEditingController(
      text: address?['street'] ?? '',
    );
    final districtController = TextEditingController(
      text: address?['district'] ?? '',
    );
    final cityController = TextEditingController(text: address?['city'] ?? '');
    final zipCodeController = TextEditingController(
      text: address?['zipCode'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            address == null ? 'Thêm địa chỉ mới' : 'Chỉnh sửa địa chỉ',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Tên người nhận'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: streetController,
                  decoration: InputDecoration(labelText: 'Địa chỉ'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: districtController,
                  decoration: InputDecoration(labelText: 'Quận/Huyện'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(labelText: 'Tỉnh/Thành phố'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: zipCodeController,
                  decoration: InputDecoration(labelText: 'Mã bưu điện'),
                  keyboardType: TextInputType.number,
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
              onPressed: () {
                final newAddress = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'street': streetController.text,
                  'district': districtController.text,
                  'city': cityController.text,
                  'zipCode': zipCodeController.text,
                };

                setState(() {
                  if (index != null) {
                    _addresses[index] = newAddress;
                  } else {
                    _addresses.add(newAddress);
                  }
                });

                Navigator.pop(context);
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc muốn xóa địa chỉ này?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _addresses.removeAt(index);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chỉnh sửa hồ sơ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Full name
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),

            SizedBox(height: 24),

            // Addresses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Địa chỉ giao hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddAddressDialog(),
                  icon: Icon(Icons.add),
                  label: Text('Thêm địa chỉ'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            if (_addresses.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Chưa có địa chỉ nào'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                address['name'] ?? 'Không có tên',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed:
                                        () => _showAddAddressDialog(
                                          address: address,
                                          index: index,
                                        ),
                                    tooltip: 'Chỉnh sửa',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteAddress(index),
                                    tooltip: 'Xóa',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (address['phone'] != null)
                            Text('SĐT: ${address['phone']}'),
                          SizedBox(height: 4),
                          Text(
                            '${address['street'] ?? ''}, ${address['district'] ?? ''}, ${address['city'] ?? ''}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            SizedBox(height: 24),

            if (_error.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(_error, style: TextStyle(color: Colors.red)),
              ),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child:
                  _isLoading
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text('Lưu thay đổi'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

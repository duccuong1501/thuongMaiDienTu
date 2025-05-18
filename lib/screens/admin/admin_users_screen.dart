import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AdminUsersScreen extends StatefulWidget {
  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  List<UserModel> _users = [];
  String _searchQuery = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      setState(() {
        _users =
            usersSnapshot.docs
                .map((doc) => UserModel.fromMap(doc.data(), doc.id))
                .toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải dữ liệu người dùng: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<UserModel> get _filteredUsers {
    return _users.where((user) {
      return _searchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleAdminStatus(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              user.isAdmin ? 'Thu hồi quyền quản trị' : 'Cấp quyền quản trị',
            ),
            content: Text(
              user.isAdmin
                  ? 'Bạn có chắc muốn thu hồi quyền quản trị của ${user.fullName}?'
                  : 'Bạn có chắc muốn cấp quyền quản trị cho ${user.fullName}?',
            ),
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
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.id)
                        .update({'isAdmin': !user.isAdmin});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          user.isAdmin
                              ? 'Đã thu hồi quyền quản trị'
                              : 'Đã cấp quyền quản trị',
                        ),
                      ),
                    );

                    _loadUsers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.isAdmin ? Colors.red : Colors.green,
                ),
                child: Text(user.isAdmin ? 'Thu hồi' : 'Cấp quyền'),
              ),
            ],
          ),
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(user.fullName),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Email: ${user.email}'),
                  SizedBox(height: 8),
                  Text('Ngày đăng ký: ${_formatDate(user.createdAt)}'),
                  SizedBox(height: 8),
                  Text('Điểm tích lũy: ${user.loyaltyPoints}'),
                  SizedBox(height: 8),
                  Text('Số đơn hàng: ${user.orders.length}'),
                  SizedBox(height: 16),

                  if (user.addresses.isNotEmpty) ...[
                    Text(
                      'Địa chỉ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ...user.addresses.map((address) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (address['name'] != null)
                              Text('${address['name']}'),
                            if (address['phone'] != null)
                              Text('SĐT: ${address['phone']}'),
                            Text(
                              '${address['street'] ?? ''}, ${address['district'] ?? ''}, ${address['city'] ?? ''}',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Đóng'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý người dùng')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Users list
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty
                    ? _buildErrorWidget()
                    : _filteredUsers.isEmpty
                    ? Center(child: Text('Không tìm thấy người dùng nào'))
                    : _buildUsersList(),
          ),
        ],
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
          ElevatedButton(onPressed: _loadUsers, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  user.isAdmin ? Colors.purple.shade100 : Colors.blue.shade100,
              child: Icon(
                Icons.person,
                color: user.isAdmin ? Colors.purple : Colors.blue,
              ),
            ),
            title: Text(
              user.fullName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Text('Đăng ký: ${_formatDate(user.createdAt)}'),
                Text(
                  'Điểm: ${user.loyaltyPoints} - Đơn hàng: ${user.orders.length}',
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.isAdmin)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                // IconButton(
                //   icon: Icon(
                //     user.isAdmin
                //         ? Icons.admin_panel_settings_off
                //         : Icons.admin_panel_settings,
                //     color: user.isAdmin ? Colors.red : Colors.green,
                //   ),
                //   onPressed: () => _toggleAdminStatus(user),
                //   tooltip: user.isAdmin ? 'Thu hồi quyền' : 'Cấp quyền',
                // ),
              ],
            ),
            onTap: () => _showUserDetails(user),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

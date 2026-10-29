import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SabCargo Users"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: ApiService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService.showDataLoadError(
                context,
                'users',
                snapshot.error.toString(),
              );
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load users',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            var users = snapshot.data as List;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService.showDataLoaded(
                context,
                'users',
                users.length,
              );
            });

            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No users found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Users will appear here when registered',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Force rebuild to reload data
                setState(() {});
              },
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          user['fullName']
                                  ?.toString()
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user['fullName'] ?? 'Unknown User'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? 'No email'),
                          if (user['phone'] != null)
                            Text(
                              user['phone'],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteUser(context, user['id'], user['fullName']),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const Center(child: Text('No data available'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteUser(BuildContext context, int userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteUser(userId);
                NotificationService.showDataSaved(context, 'User deletion');
                // Refresh the screen
                setState(() {});
              } catch (e) {
                NotificationService.showDataSaveError(
                  context,
                  'user deletion',
                  e.toString(),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(labelText: 'PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  phoneController.text.isEmpty ||
                  pinController.text.isEmpty) {
                NotificationService.showWarning(
                  context,
                  'Please fill all fields',
                );
                return;
              }

              Navigator.pop(context);
              try {
                await ApiService.createUser(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  pin: pinController.text.trim(),
                );
                NotificationService.showDataSaved(context, 'User');
                // Refresh the screen
                setState(() {});
              } catch (e) {
                NotificationService.showDataSaveError(
                  context,
                  'user',
                  e.toString(),
                );
              }
            },
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }
}

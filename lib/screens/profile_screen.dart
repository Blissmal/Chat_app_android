import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/user.dart' as app_user;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final currentUserId = authService.currentUserId;

    if (currentUserId == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final file = File(pickedFile.path);
      final imageUrl = await storageService.uploadProfileImage(
        currentUserId,
        file,
      );

      await databaseService.updateUser(currentUserId, {
        'profileImageUrl': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile(app_user.User currentUser) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      await databaseService.updateUser(currentUser.id, {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
      });

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    // If user didn't confirm, return early
    if (confirm != true) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final currentUserId = authService.currentUserId;

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Set user offline before signing out
      if (currentUserId != null) {
        await databaseService.setUserOffline(currentUserId);
      }
      await authService.signOut();

      // Close loading dialog if still mounted
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog if still mounted
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.currentUserId;

    if (currentUserId == null) return const Scaffold(body: Center(child: Text('Login Required')));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          )
        ],
      ),
      body: StreamBuilder<app_user.User?>(
        stream: databaseService.getUserStream(currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final user = snapshot.data!;
          if (!_isEditing) {
            _nameController.text = user.name;
            _bioController.text = user.bio ?? '';
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileImage(user, theme),
                const SizedBox(height: 16),

                // Name and Status
                Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _buildStatusBadge(user.status == 'online'),

                const SizedBox(height: 40),

                // Information Section
                _buildInfoCard(
                  title: 'Display Name',
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'About Me',
                  controller: _bioController,
                  icon: Icons.chat_bubble_outline_rounded,
                  enabled: _isEditing,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  title: 'Email Address',
                  value: user.email,
                  icon: Icons.alternate_email_rounded,
                ),

                const SizedBox(height: 40),
                _buildActionButtons(user),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImage(app_user.User user, ThemeData theme) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.grey[100],
              backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
              child: user.profileImageUrl == null
                  ? Text(user.name[0], style: TextStyle(fontSize: 40, color: theme.primaryColor))
                  : null,
            ),
          ),
          GestureDetector(
            onTap: _isEditing ? _pickAndUploadImage : () => setState(() => _isEditing = true),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isEditing ? theme.primaryColor : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Icon(
                _isEditing ? Icons.camera_alt_rounded : Icons.edit_rounded,
                size: 20,
                color: _isEditing ? Colors.white : theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: isOnline ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Active Now' : 'Offline',
            style: TextStyle(fontSize: 12, color: isOnline ? Colors.green[700] : Colors.grey[600], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required TextEditingController controller, required IconData icon, bool enabled = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? Colors.blue.withOpacity(0.3) : Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: Icon(icon, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons(app_user.User user) {
    if (!_isEditing) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => setState(() => _isEditing = false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _updateProfile(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
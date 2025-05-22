import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_app/services/user_service.dart';
import 'package:task_manager_app/services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? user;
  bool _isLoading = true;
  bool _uploading = false;
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await UserService.getProfile();
    if (!mounted) return;

    setState(() {
      user = data;
      _isLoading = false;
    });
  }

  Future<void> _editNameDialog(String current) async {
    final controller = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return; // user cancelled
    final newName = controller.text.trim();
    if (newName.isEmpty || newName == current) return;

    setState(() => _savingName = true);
    final success = await UserService.updateName(newName); // <-- service call
    if (!mounted) return;

    if (success) {
      await _loadUser(); // refresh profile
      setState(() => _savingName = false); // Add this line
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update name')),
      );
      setState(() => _savingName = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    final ok = await UserService.updateAvatar(File(picked.path));
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Avatar updated')));
      _loadUser();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update avatar')));
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          centerTitle: true,
          backgroundColor: _appBarBrown,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Failed to load profile')),
      );
    }

    final avatarUrl = user!['avatarUrl'] as String?;
    final createdIso = user!['created'].toString();
    final created = DateTime.tryParse(createdIso);
    final joined = created != null
        ? '${created.day}/${created.month}/${created.year}'
        : createdIso;
    final username = user!['name']?.toString() ?? 'Unknown';

    return Scaffold(
      backgroundColor: _bgBeige,
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        backgroundColor: _appBarBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _appBarBrown,
            padding: const EdgeInsets.only(bottom: 24, top: 16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 100,
                      width: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _avatarBg,
                      ),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? Image.network(avatarUrl, fit: BoxFit.cover)
                            : const Icon(Icons.person,
                                size: 50, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploading ? null : _pickAndUpload,
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: const BoxDecoration(
                              color: _cameraBadge, shape: BoxShape.circle),
                          child: _uploading
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          _cameraIconBrown)),
                                )
                              : const Icon(Icons.camera_alt,
                                  color: _cameraIconBrown, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(username,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Account Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Card(
                    color: _cardLavender,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _nameRow(username), // editable name row (unchanged)
                          const Divider(),
                          _infoRow('Created Date',
                              joined) // ← was _nameRow(joined) – fixed
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await AuthService.logoutUser();
                        if (mounted) {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/login', (_) => false);
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label:
                          const Text('Logout', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _btnDanger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            Text(v,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _nameRow(String currentName) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Username',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
        subtitle: Text(currentName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: _savingName
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editNameDialog(currentName),
              ),
      );
}

/* ---------- colour constants ---------- */
const _bgBeige = Color(0xFFEDE8E6);
const _appBarBrown = Color(0xFF795548);
const _cameraBadge = Color(0xFFBCAAA4);
const _cameraIconBrown = Color(0xFF5D4037);
const _cardLavender = Color(0xFFF8F1FA);
const _btnDanger = Color(0xFFD32F2F);
const _avatarBg = Color(0xFFF5F5F5);

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_app/services/user_service.dart';
import 'package:task_manager_app/services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? user;
  bool _isLoading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  /* ─── fetch profile + build avatar URL ────────────────────── */
  Future<void> _loadUser() async {
    final data = await UserService.getUserProfile();
    if (data != null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final avatarField = data['avatar'];
      if (avatarField != null && avatarField.toString().isNotEmpty) {
        final userId = data['id'];
        data['avatarUrl'] = 'http://10.0.2.2:8090/api/files/_pb_users_auth_/'
            '$userId/$avatarField?token=$token';
      } else {
        data['avatarUrl'] = null;
      }
    }
    if (mounted) {
      setState(() {
        user = data;
        _isLoading = false;
      });
    }
  }

  /* ─── pick image & upload ─────────────────────────────────── */
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
      _loadUser(); // refresh profile + avatar URL
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update avatar')));
      setState(() => _uploading = false);
    }
  }

  /* ─── UI ──────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
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
        title: const Text('Profile'),
        backgroundColor: _appBarBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          /* ------------ header ------------ */
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

          /* ------------ body ------------ */
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
                          _infoRow('Username', username),
                          const Divider(),
                          _infoRow('Created', joined),
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
}

/* ---------- colour constants ---------- */
const _bgBeige = Color(0xFFEDE8E6);
const _appBarBrown = Color(0xFF795548);
const _cameraBadge = Color(0xFFBCAAA4);
const _cameraIconBrown = Color(0xFF5D4037);
const _cardLavender = Color(0xFFF8F1FA);
const _btnDanger = Color(0xFFD32F2F);
const _avatarBg = Color(0xFFF5F5F5);

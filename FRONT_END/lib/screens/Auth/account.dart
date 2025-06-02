/* account_screen.dart
   Fully-contained version – no missing helpers */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:task_manager_app/services/user_service.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/invite_service.dart';
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

  /* quick stats */
  int _groupsCount = 0;
  int _invitesCount = 0;

  /* ───────────────────────── init ───────────────────────── */
  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  /* ───────────── fetch profile + tiny counts ───────────── */
  Future<void> _loadEverything() async {
    setState(() => _isLoading = true);

    final profile = UserService.getProfile(); // Future<Map>
    final myGroups = GroupService.getGroups();
    final invites = InviteService.listMyInvites();

    user = await profile;
    _groupsCount = (await myGroups).length;
    _invitesCount =
        (await invites).where((e) => e['status'] == 'pending').length;

    if (mounted) setState(() => _isLoading = false);

    // if (mounted) setState(() => _isLoading = false);
    //   user = await profile;
    //   _groupsCount = (await myGroups).length;
    //   _invitesCount = (await invites).length;

    //   if (mounted) setState(() => _isLoading = false);
  }

  /* ───────────────────── edit name ───────────────────── */
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
    if (ok != true) return;
    final newName = controller.text.trim();
    if (newName.isEmpty || newName == current) return;

    setState(() => _savingName = true);
    final success = await UserService.updateName(newName);
    if (!mounted) return;

    if (success) {
      await _loadEverything();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name updated')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not update name')));
      setState(() => _savingName = false);
    }
  }

  /* ───────────────────── avatar upload ───────────────────── */
  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker().pickImage(
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
      _loadEverything();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update avatar')));
      setState(() => _uploading = false);
    }
  }

  /* ───────────────────── build ───────────────────── */
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) return _errorScaffold();

    final avatarUrl = user!['avatarUrl'] as String?;
    final createdIso = user!['created'].toString();
    final joined = _fmtDate(DateTime.parse(createdIso));
    final username = user!['name'] ?? 'Unknown';
    final email = user!['email'] ?? '—';

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
          _header(avatarUrl, username),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Account Information'),
                  _infoCard(joined, email),
                  const SizedBox(height: 16),
                  _sectionTitle('Quick Stats'),
                  _quickStatsRow(),
                  const Spacer(),
                  _logoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ───────────────────── widgets ───────────────────── */

  Widget _header(String? url, String name) => Container(
        width: double.infinity,
        color: _appBarBrown,
        padding: const EdgeInsets.only(bottom: 24, top: 16),
        child: Column(
          children: [
            _avatarStack(url),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      );

  Widget _avatarStack(String? url) => Stack(
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
              child: url != null
                  ? Image.network(url, fit: BoxFit.cover)
                  : const Icon(Icons.person, size: 50, color: Colors.grey),
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
                            valueColor:
                                AlwaysStoppedAnimation(_cameraIconBrown)),
                      )
                    : const Icon(Icons.camera_alt,
                        color: _cameraIconBrown, size: 16),
              ),
            ),
          ),
        ],
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  Widget _infoCard(String joined, String email) => Card(
        color: _cardLavender,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _nameRow(user!['name'] ?? 'Unknown'),
              const Divider(),
              _infoRow('Email', email),
              const Divider(),
              _infoRow('Member since', joined),
            ],
          ),
        ),
      );

  Widget _quickStatsRow() => Wrap(
        spacing: 12,
        children: [
          _statChip(Icons.group, 'Groups', _groupsCount),
          _statChip(Icons.mail, 'Invites', _invitesCount),
        ],
      );

  Chip _statChip(IconData ic, String label, int n) => Chip(
        avatar: Icon(ic, size: 18, color: Colors.white),
        label: Text('$n  $label',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        backgroundColor: _appBarBrown,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );

  Widget _logoutButton() => SizedBox(
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
          label: const Text('Logout', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _btnDanger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      );

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

  Widget _errorScaffold() => Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          centerTitle: true,
          backgroundColor: _appBarBrown,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Failed to load profile')),
      );

  /* ───────────────── helpers ───────────────── */
  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

/* ---------- colour palette ---------- */
const _bgBeige = Color(0xFFEDE8E6);
const _appBarBrown = Color(0xFF795548);
const _cameraBadge = Color(0xFFBCAAA4);
const _cameraIconBrown = Color(0xFF5D4037);
const _cardLavender = Color(0xFFF8F1FA);
const _btnDanger = Color(0xFFD32F2F);
const _avatarBg = Color(0xFFF5F5F5);

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';

import '../Auth/auth_manager.dart';
import 'comments_manager.dart';

class CommentsSection extends StatefulWidget {
  final String taskId;
  const CommentsSection({Key? key, required this.taskId}) : super(key: key);

  @override
  _CommentsSectionState createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('en', timeago.EnMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentsProvider>().loadComments(widget.taskId);
    });
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked);
      });
    }
  }

  void _removeImage(int idx) {
    setState(() => _images.removeAt(idx));
  }

  Future<void> _showEditDialog(Map<String, dynamic> c) async {
    final editController = TextEditingController(text: c['contents'] ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Update your comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updated = editController.text.trim();
              if (updated.isNotEmpty) {
                await context.read<CommentsProvider>().updateComment(
                      widget.taskId,
                      c['id'],
                      contents: updated,
                    );
                await context
                    .read<CommentsProvider>()
                    .loadComments(widget.taskId);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCommentOptions(BuildContext ctx, CommentsProvider prov,
      Map<String, dynamic> c, String currentUserId) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c['author'] == currentUserId)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  prov.deleteComment(widget.taskId, c['id']);
                  Navigator.pop(ctx);
                },
              ),
            if (c['author'] == currentUserId)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(c);
                },
              ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                _controller.text = '@${c['expand']?['author']?['name'] ?? ''} ';
                FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _images.isEmpty) return;
    final attachments = _images.map((x) => x.path).toList();
    await context.read<CommentsProvider>().createComment(
          widget.taskId,
          text,
          attachments: attachments,
        );
    _controller.clear();
    setState(() => _images.clear());
    await context.read<CommentsProvider>().loadComments(widget.taskId);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CommentsProvider>();
    final comments = prov.comments;
    final currentUserId = context.watch<AuthManager>().userId;
    final count = comments.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.comment_outlined),
              const SizedBox(width: 8),
              Text(
                'Comments ($count)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : comments.isEmpty
                  ? const Center(child: Text('No comments yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i];
                        final author = c['expand']?['author'];
                        final createdAt =
                            DateTime.tryParse(c['created'] ?? '') ??
                                DateTime.now();
                        final updatedAt = c['updated'] != null
                            ? DateTime.tryParse(c['updated'] ?? '')
                            : null;
                        final timeLabel =
                            timeago.format(createdAt, locale: 'en');
                        final editTime =
                            updatedAt != null && updatedAt.isAfter(createdAt)
                                ? timeago.format(updatedAt, locale: 'en')
                                : null;
                        final displayLabel =
                            editTime != null ? 'edited $editTime' : timeLabel;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Card(
                                  elevation: 1,
                                  margin:
                                      const EdgeInsets.fromLTRB(40, 6, 12, 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                author?['name'] ?? 'Unknown',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(c['contents'] ?? ''),
                                              if ((c['attachments'] as List?)
                                                      ?.isNotEmpty ??
                                                  false) ...[
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                  height: 80,
                                                  child: ListView.separated(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount: (c['attachments']
                                                            as List)
                                                        .length,
                                                    separatorBuilder: (_, __) =>
                                                        const SizedBox(
                                                            width: 8),
                                                    itemBuilder: (_, idxImg) =>
                                                        ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.network(
                                                        c['attachments']
                                                            [idxImg],
                                                        width: 80,
                                                        height: 80,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.more_vert),
                                          onPressed: () => _showCommentOptions(
                                            context,
                                            prov,
                                            c,
                                            currentUserId!,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -10,
                                  top: 4,
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        author?['avatarUrl'] != null
                                            ? NetworkImage(author['avatarUrl'])
                                            : null,
                                    child: author?['avatarUrl'] == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 56, bottom: 6),
                              child: Text(
                                displayLabel,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
        if (_images.isNotEmpty) ...[
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, idx) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_images[idx].path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: IconButton(
                      icon:
                          const Icon(Icons.cancel, size: 18, color: Colors.red),
                      onPressed: () => _removeImage(idx),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: _pickImages,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Post your comments...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                  ),
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                onPressed: (_controller.text.trim().isEmpty && _images.isEmpty)
                    ? null
                    : _submitComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

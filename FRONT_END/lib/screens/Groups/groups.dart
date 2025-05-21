import 'package:flutter/material.dart';
import '../../models/groups.dart';
import 'edit_dialog.dart';
import 'groups_manager.dart';

class GroupScreen extends StatefulWidget {
  static const routeName = '/groups';
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Group currentGroup;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void updateGroup(Group updatedGroup) {
    setState(() {
      final index = mockGroups.indexWhere((g) => g.id == updatedGroup.id);
      if (index != -1) {
        mockGroups[index] = updatedGroup;
        currentGroup = updatedGroup;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Groups"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showEditGroupDialog(context, currentGroup, updateGroup);
            },
          ),
        ],
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.deepPurple),
            insets: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Members"),
            Tab(text: "Tasks"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          const Center(child: Text("Members tab content")),
          const Center(child: Text("Tasks tab content")),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: mockGroups.length,
      itemBuilder: (context, index) {
        final group = mockGroups[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EDFF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                group.description,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                      "Created: ${group.created.toLocal().toIso8601String().split('T').first}"),
                  const SizedBox(width: 16),
                  const Icon(Icons.update, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                      "Updated: ${group.updated.toLocal().toIso8601String().split('T').first}"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

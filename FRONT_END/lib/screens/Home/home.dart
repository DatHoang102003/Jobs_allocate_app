import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../custom_drawer.dart';
import '../Groups/Overview/overview.dart';
import '../Groups/create_dialog.dart';
import '../Groups/group_search.dart';
import '../Groups/groups_manager.dart';
import '../Members/membership_manager.dart';
import '../Tasks/tasks_manager.dart';
import 'analysis.dart';
import 'widgets/group_card.dart';
import 'widgets/in_progress_section.dart';
import 'widgets/today_task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  late TabController _tabController;
  bool _showAllGroups = false;
  final int _maxInitialGroups = 5;
  Offset _fabOffset = const Offset(0, 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final gp = context.read<GroupsProvider>();
    final tp = context.read<TasksProvider>();
    try {
      await gp.fetchGroups();
    } catch (e) {
      debugPrint('❌ Error loading groups: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải được danh sách nhóm')),
        );
      }
    }
    try {
      await tp.loadTasks(date: selectedDate);
    } catch (e) {
      debugPrint('❌ Error loading tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải được công việc hôm nay')),
        );
      }
    }
  }

  void _updateSelectedDate(DateTime date) {
    setState(() => selectedDate = date);
    context.read<TasksProvider>().loadTasks(date: date);
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupsProvider>();
    final tp = context.watch<TasksProvider>();
    final mp = context.watch<MemberManager>();

    final isBusy = gp.isLoading || mp.isLoading;
    final allGroups = [
      ...gp.adminGroups,
      ...gp.memberGroups,
    ];
    final displayedGroups =
        _showAllGroups ? allGroups : allGroups.take(_maxInitialGroups).toList();
    final hasMoreGroups = allGroups.length > _maxInitialGroups;

    return Scaffold(
      backgroundColor: const Color(0xFFEDE8E6),
      drawer: const CustomDrawer(),
      appBar: const _HomeAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const GroupSearch(),
              ),
              const SizedBox(height: 15),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF7A86F8),
                unselectedLabelColor: Colors.black54,
                indicatorColor: const Color(0xFF7A86F8),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Analysis'),
                ],
              ),
              Expanded(
                child: isBusy
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab Overview
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TodayTaskCard(
                                  taskProvider: tp,
                                  selectedDate: selectedDate,
                                  onDateSelected: _updateSelectedDate,
                                ),
                                const SizedBox(height: 24),
                                const InProgressSection(),
                                const SizedBox(height: 24),

                                // All Groups header với View More
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'All Groups (${allGroups.length})',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          GroupScreen.routeName,
                                        );
                                      },
                                      child: const Text(
                                        'View More',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF7A86F8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Danh sách nhóm tóm tắt
                                ...displayedGroups.map((g) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: GroupCard(
                                        key: ValueKey(g.id),
                                        groupProvider: gp,
                                        taskProvider: tp,
                                        memberProvider: mp,
                                        group: g,
                                      ),
                                    )),

                                // Nút Load more
                                if (hasMoreGroups)
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() =>
                                            _showAllGroups = !_showAllGroups);
                                      },
                                      child: Text(
                                        _showAllGroups ? 'Hide' : 'Load more',
                                        style: const TextStyle(
                                          color: Color(0xFF7A86F8),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Tab Analysis
                          // Thay placeholder bằng AnalysisScreen
                          const AnalysisScreen(),
                        ],
                      ),
              ),
            ],
          ),

          // Draggable FAB “Add group”
          Positioned(
            left: MediaQuery.of(context).size.width * 0.5 - 80 + _fabOffset.dx,
            top: MediaQuery.of(context).size.height - 150 + _fabOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _fabOffset += details.delta;
                  final screenW = MediaQuery.of(context).size.width;
                  final screenH = MediaQuery.of(context).size.height;
                  _fabOffset = Offset(
                    _fabOffset.dx.clamp(-screenW * 0.4, screenW * 0.4),
                    _fabOffset.dy.clamp(-screenH * 0.6, screenH * 0.2),
                  );
                });
              },
              child: ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CreateGroupDialog(),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add group',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A86F8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Dashboard',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

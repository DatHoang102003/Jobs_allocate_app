import '../../models/tasks.dart';

final mockTasks = [
  Task(
    id: 'task1',
    groupId: 'grp1',
    title: 'Setup Flutter Project',
    description:
        'Initialize flutter project with Firebase and state management',
    assignUserId: 'john_doe',
    status: 'in_progress',
    deadline: DateTime.now().add(const Duration(days: 5)),
    createdByUserId: 'admin_user',
  ),
  Task(
    id: 'task2',
    groupId: 'grp1',
    title: 'Implement Login',
    description: 'Create login UI and connect with PocketBase API',
    assignUserId: 'jane_smith',
    status: 'pending',
    deadline: DateTime.now().add(const Duration(days: 3)),
    createdByUserId: 'john_doe',
  ),
  Task(
    id: 'task3',
    groupId: 'grp2',
    title: 'Design Task Card UI',
    description: 'Mockup task card and convert to Flutter widget',
    assignUserId: 'john_doe',
    status: 'completed',
    deadline: null,
    createdByUserId: 'jane_smith',
  ),
];

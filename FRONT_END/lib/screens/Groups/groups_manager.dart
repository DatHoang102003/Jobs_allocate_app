import '../../models/groups.dart';

final List<Group> mockGroups = [
  Group(
    id: 'grp001',
    name: 'Study Group A',
    description: 'A group for students studying Flutter.',
    owner: 'tientom01',
    created: DateTime.now().subtract(const Duration(days: 10)),
    updated: DateTime.now(),
  ),
  Group(
    id: 'grp002',
    name: 'Math Enthusiasts',
    description: 'Sharing knowledge about mathematics.',
    owner: 'johndoe',
    created: DateTime.now().subtract(const Duration(days: 20)),
    updated: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Group(
    id: 'grp003',
    name: 'Daily Coders',
    description: 'Discuss coding challenges daily.',
    owner: 'janesmith',
    created: DateTime.now().subtract(const Duration(days: 5)),
    updated: DateTime.now(),
  ),
];

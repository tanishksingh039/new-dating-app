import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_data_service.dart';
import '../../../constants/app_colors.dart';

/// Admin User Management Widget
/// Handles user listing, filtering, and management actions
class AdminUserManagement extends StatefulWidget {
  final Function(String) onUserAction;
  final Function(String) onError;

  const AdminUserManagement({
    super.key,
    required this.onUserAction,
    required this.onError,
  });

  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<AdminUser> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  UserFilter? _currentFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_isLoading) {
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _users.clear();
        _lastDocument = null;
        _hasMore = true;
      }
    });

    try {
      final result = await AdminDataService.getUsers(
        limit: 20,
        lastDocument: refresh ? null : _lastDocument,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        filter: _currentFilter,
      );

      setState(() {
        if (refresh) {
          _users = result.users;
        } else {
          _users.addAll(result.users);
        }
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      widget.onError('Failed to load users: $e');
    }
  }

  Future<void> _loadMoreUsers() async {
    if (!_hasMore || _isLoading) return;
    await _loadUsers();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _debounceSearch();
  }

  Timer? _searchTimer;
  void _debounceSearch() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _loadUsers(refresh: true);
    });
  }

  void _onFilterChanged(UserFilter? filter) {
    setState(() => _currentFilter = filter);
    _loadUsers(refresh: true);
  }

  Future<void> _toggleUserBlock(AdminUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isBlocked ? 'Unblock User' : 'Block User'),
        content: Text(
          user.isBlocked
              ? 'Are you sure you want to unblock ${user.name}?'
              : 'Are you sure you want to block ${user.name}? They will not be able to use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isBlocked ? Colors.green : Colors.red,
            ),
            child: Text(user.isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminDataService.toggleUserBlock(user.id, !user.isBlocked);
        widget.onUserAction('User ${user.isBlocked ? 'unblocked' : 'blocked'} successfully');
        _loadUsers(refresh: true);
      } catch (e) {
        widget.onError('Failed to ${user.isBlocked ? 'unblock' : 'block'} user: $e');
      }
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to permanently delete ${user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminDataService.deleteUser(user.id);
        widget.onUserAction('User deleted successfully');
        _loadUsers(refresh: true);
      } catch (e) {
        widget.onError('Failed to delete user: $e');
      }
    }
  }

  void _showUserDetails(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photos.isNotEmpty
                        ? NetworkImage(user.photos.first)
                        : null,
                    child: user.photos.isEmpty
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Phone', user.phoneNumber),
              _buildDetailRow('Premium', user.isPremium ? 'Yes' : 'No'),
              _buildDetailRow('Verified', user.isVerified ? 'Yes' : 'No'),
              _buildDetailRow('Blocked', user.isBlocked ? 'Yes' : 'No'),
              _buildDetailRow('Flagged', user.isFlagged ? 'Yes' : 'No'),
              if (user.lastActive != null)
                _buildDetailRow('Last Active', _formatDate(user.lastActive!)),
              if (user.createdAt != null)
                _buildDetailRow('Joined', _formatDate(user.createdAt!)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search users by name, email, or phone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _currentFilter == null,
                      onSelected: (_) => _onFilterChanged(null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Premium'),
                      selected: _currentFilter == UserFilter.premium,
                      onSelected: (_) => _onFilterChanged(UserFilter.premium),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Verified'),
                      selected: _currentFilter == UserFilter.verified,
                      onSelected: (_) => _onFilterChanged(UserFilter.verified),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Flagged'),
                      selected: _currentFilter == UserFilter.flagged,
                      onSelected: (_) => _onFilterChanged(UserFilter.flagged),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Active'),
                      selected: _currentFilter == UserFilter.active,
                      onSelected: (_) => _onFilterChanged(UserFilter.active),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Users list
        Expanded(
          child: _isLoading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _users.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _users.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final user = _users[index];
                        return _buildUserCard(user);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(AdminUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: user.photos.isNotEmpty
              ? NetworkImage(user.photos.first)
              : null,
          child: user.photos.isEmpty
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (user.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            if (user.isVerified) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.verified,
                size: 16,
                color: Colors.blue.shade600,
              ),
            ],
            if (user.isBlocked) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.block,
                size: 16,
                color: Colors.red.shade600,
              ),
            ],
            if (user.isFlagged) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.flag,
                size: 16,
                color: Colors.orange.shade600,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email),
            Text(user.phoneNumber),
            if (user.lastActive != null)
              Text(
                'Last active: ${_formatDate(user.lastActive!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'view':
                _showUserDetails(user);
                break;
              case 'block':
                _toggleUserBlock(user);
                break;
              case 'delete':
                _deleteUser(user);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: ListTile(
                leading: Icon(
                  user.isBlocked ? Icons.check_circle : Icons.block,
                  color: user.isBlocked ? Colors.green : Colors.red,
                ),
                title: Text(user.isBlocked ? 'Unblock' : 'Block'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }
}

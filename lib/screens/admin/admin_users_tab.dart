import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_logger.dart';
import '../../services/admin_users_service.dart';
import 'user_details_screen.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({Key? key}) : super(key: key);

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  final AdminUsersService _adminService = AdminUsersService();
  
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Premium, Verified, Flagged
  
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('═══════════════════════════════════════');
      print('[AdminUsersTab] 🔍 Loading users...');
      print('[AdminUsersTab] Admin Status: ${_adminService.isCurrentUserAdmin()}');
      print('═══════════════════════════════════════');

      final users = await _adminService.getAllUsers(forceRefresh: forceRefresh);
      
      setState(() {
        _allUsers = users;
        _applyFilters();
        _isLoading = false;
      });
      
      print('[AdminUsersTab] ✅ Loaded ${users.length} users successfully');
    } catch (e) {
      print('[AdminUsersTab] ❌ Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<UserModel> filtered = _allUsers;

    // Apply category filter
    if (_selectedFilter != 'All') {
      filtered = _adminService.filterUsers(_selectedFilter);
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final name = user.name.toLowerCase();
        final phone = user.phoneNumber?.toLowerCase() ?? '';
        return name.contains(_searchQuery) || phone.contains(_searchQuery);
      }).toList();
    }

    _filteredUsers = filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by name or phone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                    _applyFilters();
                  });
                },
              ),
              const SizedBox(height: 12),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', Icons.people),
                    const SizedBox(width: 8),
                    _buildFilterChip('Premium', Icons.star),
                    const SizedBox(width: 8),
                    _buildFilterChip('Verified', Icons.verified),
                    const SizedBox(width: 8),
                    _buildFilterChip('Flagged', Icons.flag),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Users list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading users...'),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              'Error Loading Users',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _loadUsers(forceRefresh: true),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _selectedFilter != 'All'
                                    ? 'No users match your filters'
                                    : 'No users found',
                              ),
                              if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedFilter = 'All';
                                      _searchController.clear();
                                      _applyFilters();
                                    });
                                  },
                                  child: const Text('Clear Filters'),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadUsers(forceRefresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredUsers.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // Header with count and refresh button
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${_filteredUsers.length} users',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.refresh),
                                        onPressed: () => _loadUsers(forceRefresh: true),
                                        tooltip: 'Refresh',
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              final user = _filteredUsers[index - 1];
                              return _buildUserCard(user);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    final now = DateTime.now();
    final lastActive = user.lastActive;
    final isActive = lastActive != null && now.difference(lastActive).inDays <= 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsScreen(user: user),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: user.photos.isNotEmpty
                        ? NetworkImage(user.photos[0])
                        : null,
                    child: user.photos.isEmpty
                        ? const Icon(Icons.person, size: 24)
                        : null,
                  ),
                  if (isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (user.isVerified)
                          const Icon(Icons.verified, size: 14, color: Colors.blue),
                        if (user.isPremium)
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phoneNumber.isNotEmpty ? user.phoneNumber : 'No phone',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    Color chipColor;
    
    switch (label) {
      case 'Premium':
        chipColor = Colors.amber;
        break;
      case 'Verified':
        chipColor = Colors.blue;
        break;
      case 'Flagged':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : chipColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
          _applyFilters();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? chipColor : chipColor.withOpacity(0.3),
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}

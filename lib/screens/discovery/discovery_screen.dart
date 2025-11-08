import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/discovery_service.dart';
import 'profile_detail_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final DiscoveryService _service = DiscoveryService();
  List<UserModel> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // Not signed in - show empty
        setState(() {
          _profiles = [];
          _isLoading = false;
        });
        return;
      }

      final profiles = await _service.getDiscoveryProfiles(currentUser.uid);
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading discovery profiles: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfiles,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _profiles.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('No profiles found')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final user = _profiles[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: user.photos.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(user.photos[0]),
                                  radius: 28,
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                          title: Text(user.name.isEmpty ? 'No name' : user.name),
                          subtitle: Text(user.bio.isEmpty ? 'No bio' : user.bio),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileDetailScreen(
                                  user: user,
                                  onLike: () {},
                                  onPass: () {},
                                  onSuperLike: () {},
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

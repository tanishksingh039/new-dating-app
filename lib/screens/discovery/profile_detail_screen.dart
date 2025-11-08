import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../widgets/action_buttons.dart';

class ProfileDetailScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback onSuperLike;

  const ProfileDetailScreen({
    Key? key,
    required this.user,
    required this.onLike,
    required this.onPass,
    required this.onSuperLike,
  }) : super(key: key);

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final age = widget.user.dateOfBirth != null
        ? _calculateAge(widget.user.dateOfBirth!)
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // Photo gallery
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.6,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo page view
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPhotoIndex = index);
                        },
                        itemCount: widget.user.photos.length,
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: widget.user.photos[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),

                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // Photo indicators
                      if (widget.user.photos.length > 1)
                        Positioned(
                          top: 60,
                          left: 10,
                          right: 10,
                          child: Row(
                            children: List.generate(
                              widget.user.photos.length,
                              (index) => Expanded(
                                child: Container(
                                  height: 3,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: index == _currentPhotoIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Profile details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and age
                      Row(
                        children: [
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$age',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (widget.user.isVerified) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '2 kilometers away',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Bio section
                      if (widget.user.bio.isNotEmpty) ...[
                        _buildSectionTitle('About ${widget.user.name}'),
                        const SizedBox(height: 12),
                        Text(
                          widget.user.bio,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                      ],

                      // Interests section
                      if (widget.user.interests.isNotEmpty) ...[
                        _buildSectionTitle('Interests'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: widget.user.interests.map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.pink.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.pink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                      ],

                      // Basic info section
                      _buildSectionTitle('Basics'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.cake, 'Age', '$age years old'),
                      _buildInfoRow(
                        widget.user.gender == 'Male'
                            ? Icons.male
                            : widget.user.gender == 'Female'
                                ? Icons.female
                                : Icons.transgender,
                        'Gender',
                        widget.user.gender.isEmpty ? 'Not specified' : widget.user.gender,
                      ),
                      if (widget.user.preferences['lookingFor'] != null)
                        _buildInfoRow(
                          Icons.favorite,
                          'Looking for',
                          widget.user.preferences['lookingFor'].toString(),
                        ),

                      const SizedBox(height: 100), // Space for action buttons
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Action buttons at bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: ActionButtons(
              onPass: () {
                widget.onPass();
                Navigator.pop(context);
              },
              onSuperLike: () {
                widget.onSuperLike();
                Navigator.pop(context);
              },
              onLike: () {
                widget.onLike();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: Colors.grey[700]),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
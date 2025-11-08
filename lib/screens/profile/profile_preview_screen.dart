import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/user_model.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final UserModel user;

  const ProfilePreviewScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final age = widget.user.dateOfBirth != null
        ? _calculateAge(widget.user.dateOfBirth!)
        : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // Photo carousel
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.6,
                pinned: true,
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.user.photos.isNotEmpty
                      ? Stack(
                          children: [
                            // Photo PageView
                            PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() => _currentPhotoIndex = index);
                              },
                              itemCount: widget.user.photos.length,
                              itemBuilder: (context, index) {
                                return FadeIn(
                                  child: CachedNetworkImage(
                                    imageUrl: widget.user.photos[index],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[900],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Gradient overlay
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Photo indicators
                            if (widget.user.photos.length > 1)
                              Positioned(
                                top: 60,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: List.generate(
                                      widget.user.photos.length,
                                      (index) => Expanded(
                                        child: Container(
                                          height: 3,
                                          margin: const EdgeInsets.symmetric(horizontal: 2),
                                          decoration: BoxDecoration(
                                            color: _currentPhotoIndex == index
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Name and age overlay
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: FadeInUp(
                                delay: const Duration(milliseconds: 300),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.user.name,
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black45,
                                                  offset: Offset(0, 2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          ' $age',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black45,
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.user.isVerified) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 28,
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (widget.user.isPremium)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.amber[700]!, Colors.orange[600]!],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.star, color: Colors.white, size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              'Premium',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                ),
              ),

              // Profile details
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio section
                      if (widget.user.bio.isNotEmpty)
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 20, color: Colors.pink),
                                    SizedBox(width: 8),
                                    Text(
                                      'About Me',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.user.bio,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Interests section
                      if (widget.user.interests.isNotEmpty)
                        FadeInUp(
                          delay: const Duration(milliseconds: 500),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.favorite_outline, size: 20, color: Colors.pink),
                                    SizedBox(width: 8),
                                    Text(
                                      'Interests',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.pink.withOpacity(0.1),
                                            Colors.purple.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: Colors.pink.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        interest,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.pink,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Basic info section
                      FadeInUp(
                        delay: const Duration(milliseconds: 600),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.person_outline, size: 20, color: Colors.pink),
                                  SizedBox(width: 8),
                                  Text(
                                    'Basic Info',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (widget.user.gender.isNotEmpty)
                                _buildInfoRow(Icons.wc, 'Gender', widget.user.gender),
                              if (age > 0)
                                _buildInfoRow(Icons.cake_outlined, 'Age', '$age years old'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom preview badge
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: FadeInUp(
              delay: const Duration(milliseconds: 700),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'This is how others see your profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.pink),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

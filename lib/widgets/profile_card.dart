import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';

/// Enhanced ProfileCard with photo carousel functionality
class ProfileCard extends StatefulWidget {
  final UserModel user;
  final bool enablePhotoCarousel;
  final bool isSpotlight;

  const ProfileCard({
    Key? key,
    required this.user,
    this.enablePhotoCarousel = true,
    this.isSpotlight = false,
  }) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  // Current photo index for carousel
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

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

  // Check if user is online (active within last 5 minutes)
  bool _isUserOnline() {
    try {
      if (widget.user.lastActive == null) return false;
      
      final now = DateTime.now();
      final difference = now.difference(widget.user.lastActive!);
      return difference.inMinutes < 5;
    } catch (e) {
      return false; // Safe fallback
    }
  }

  // Get last seen text
  String _getLastSeenText() {
    try {
      if (widget.user.lastActive == null) return '';
      
      final now = DateTime.now();
      final difference = now.difference(widget.user.lastActive!);
      
      if (difference.inMinutes < 1) {
        return 'Active just now';
      } else if (difference.inMinutes < 60) {
        return 'Active ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Active ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return 'Active ${difference.inDays}d ago';
      } else {
        return 'Active ${(difference.inDays / 7).floor()}w ago';
      }
    } catch (e) {
      return ''; // Safe fallback
    }
  }

  // Check if user allows showing online status
  bool _showOnlineStatus() {
    try {
      return widget.user.privacySettings['showOnlineStatus'] ?? true;
    } catch (e) {
      return true; // Default to showing if error
    }
  }

  // Handle tap on left/right side of card to navigate photos
  void _handlePhotoNavigation(TapUpDetails details, double cardWidth) {
    if (!widget.enablePhotoCarousel || widget.user.photos.length <= 1) return;

    final tapPosition = details.localPosition.dx;
    final isLeftSide = tapPosition < cardWidth / 2;

    setState(() {
      if (isLeftSide && _currentPhotoIndex > 0) {
        _currentPhotoIndex--;
      } else if (!isLeftSide && _currentPhotoIndex < widget.user.photos.length - 1) {
        _currentPhotoIndex++;
      }
    });

    _pageController.animateToPage(
      _currentPhotoIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final age = widget.user.dateOfBirth != null
        ? _calculateAge(widget.user.dateOfBirth!)
        : 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapUp: (details) => _handlePhotoNavigation(details, constraints.maxWidth),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo carousel
                  _buildPhotoCarousel(),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),

                  // Spotlight badge at top left
                  if (widget.isSpotlight)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildSpotlightBadge(),
                    ),

                  // Photo indicators at top
                  if (widget.user.photos.length > 1)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: _buildPhotoIndicators(),
                    ),

                  // Online status indicator at top right
                  if (_showOnlineStatus())
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildOnlineStatusIndicator(),
                    ),

                  // User info at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildUserInfo(age),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build photo carousel with PageView for smooth swiping
  Widget _buildPhotoCarousel() {
    if (widget.user.photos.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.person, size: 100, color: Colors.grey),
      );
    }

    if (widget.user.photos.length == 1 || !widget.enablePhotoCarousel) {
      return CachedNetworkImage(
        imageUrl: widget.user.photos[0],
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.person, size: 100, color: Colors.grey),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPhotoIndex = index;
        });
      },
      itemCount: widget.user.photos.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: widget.user.photos[index],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.person, size: 100, color: Colors.grey),
          ),
        );
      },
    );
  }

  /// Build photo indicators showing current photo position
  Widget _buildPhotoIndicators() {
    return Row(
      children: List.generate(
        widget.user.photos.length,
        (index) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index == _currentPhotoIndex
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  /// Build user information section at bottom of card
  Widget _buildUserInfo(int age) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name and age
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$age',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (widget.user.isVerified) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 24,
                ),
              ],
            ],
          ),

          // Location and online status
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '2 kilometers away', // TODO: Calculate real distance
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),

          // Last seen / Online status
          if (_showOnlineStatus() && widget.user.lastActive != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isUserOnline() ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isUserOnline() ? 'Online' : _getLastSeenText(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: _isUserOnline() ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

          // Bio preview
          if (widget.user.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.user.bio,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Interests preview
          if (widget.user.interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.user.interests.take(3).map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Info icon
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.user.photos.length > 1
                      ? 'Tap sides for photos'
                      : 'Tap for info',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build spotlight badge (top left corner)
  Widget _buildSpotlightBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.star,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'SPOTLIGHT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build online status indicator (top right corner)
  Widget _buildOnlineStatusIndicator() {
    if (!_isUserOnline()) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.circle,
            color: Colors.white,
            size: 10,
          ),
          SizedBox(width: 6),
          Text(
            'Online',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
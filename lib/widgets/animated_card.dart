import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated card with 3D flip effect
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle >= math.pi / 2
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}

/// Enhanced Tinder-like swipeable card with smooth animations
class TinderSwipeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;  // Reject/Pass
  final VoidCallback? onSwipeRight; // Like
  final VoidCallback? onSwipeUp;    // Super Like
  final bool isStackCard; // If true, card is in background stack

  const TinderSwipeCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.isStackCard = false,
  });

  @override
  State<TinderSwipeCard> createState() => TinderSwipeCardState();
}

class TinderSwipeCardState extends State<TinderSwipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  double _swipeDirection = 0; // -1 for left, 1 for right, 0 for none

  @override
  void initState() {
    super.initState();
    // Ultra-fast animation for buttery smooth feel
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Public method to trigger programmatic swipe
  void swipeLeft() {
    _animateCardOff(const Offset(-1.5, 0), () => widget.onSwipeLeft?.call());
  }

  void swipeRight() {
    _animateCardOff(const Offset(1.5, 0), () => widget.onSwipeRight?.call());
  }

  void swipeUp() {
    _animateCardOff(const Offset(0, -1.5), () => widget.onSwipeUp?.call());
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.isStackCard) return;
    setState(() {
      _isDragging = true;
      _controller.stop();
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.isStackCard) return;
    // Use setState less frequently for smoother performance
    _dragOffset += details.delta;
    // Determine swipe direction for overlay
    if (_dragOffset.dx.abs() > 10) {
      _swipeDirection = _dragOffset.dx > 0 ? 1 : -1;
    }
    // Force rebuild for smooth dragging
    if (mounted) {
      setState(() {});
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isStackCard) return;
    setState(() => _isDragging = false);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Very low threshold for high sensitivity (15% of screen width)
    final horizontalThreshold = screenWidth * 0.15;
    final verticalThreshold = screenHeight * 0.12;
    final velocity = details.velocity.pixelsPerSecond;

    // Check velocity for quick swipes (very low threshold for maximum responsiveness)
    final isQuickSwipe = velocity.distance > 300;

    if (_dragOffset.dx > horizontalThreshold || (isQuickSwipe && velocity.dx > 300)) {
      // Swipe right - Triggers onSwipeRight callback
      _animateCardOff(const Offset(1.5, 0.3), () => widget.onSwipeRight?.call());
    } else if (_dragOffset.dx < -horizontalThreshold || (isQuickSwipe && velocity.dx < -300)) {
      // Swipe left - Triggers onSwipeLeft callback
      _animateCardOff(const Offset(-1.5, 0.3), () => widget.onSwipeLeft?.call());
    } else if (_dragOffset.dy < -verticalThreshold || (isQuickSwipe && velocity.dy < -300)) {
      // Swipe up - SUPER LIKE
      _animateCardOff(const Offset(0, -1.5), () => widget.onSwipeUp?.call());
    } else {
      // Return to center with spring animation
      _resetCard();
    }
  }

  void _animateCardOff(Offset direction, VoidCallback onComplete) {
    final screenSize = MediaQuery.of(context).size;
    
    _positionAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(
        direction.dx * screenSize.width * 1.2,
        direction.dy * screenSize.height * 1.2,
      ),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.75).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _rotationAnimation = Tween<double>(
      begin: _dragOffset.dx / 1000,
      end: direction.dx * 0.25,
    ).animate(_controller);

    _controller.forward(from: 0).then((_) {
      if (mounted) {
        onComplete();
        setState(() {
          _dragOffset = Offset.zero;
          _swipeDirection = 0;
        });
        _controller.reset();
      }
    });
  }

  void _resetCard() {
    _positionAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
    _rotationAnimation = Tween<double>(
      begin: _dragOffset.dx / 1000,
      end: 0,
    ).animate(_controller);

    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = Offset.zero;
          _swipeDirection = 0;
        });
        _controller.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate current position and transformations
    final offset = _isDragging ? _dragOffset : _positionAnimation.value;
    final rotation = _isDragging 
        ? (_dragOffset.dx / 1000).clamp(-0.3, 0.3) 
        : _rotationAnimation.value;
    final scale = _isDragging 
        ? (1 - (offset.distance / 3000)).clamp(0.85, 1.0)
        : _scaleAnimation.value;

    // Calculate overlay opacity based on swipe distance
    final overlayOpacity = (_dragOffset.dx.abs() / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              children: [
                // Main card content
                widget.child,
                
                // Swipe overlay indicators
                if (_isDragging && overlayOpacity > 0.1)
                  _buildSwipeOverlay(overlayOpacity),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build overlay that shows during swipe (heart or cross)
  Widget _buildSwipeOverlay(double opacity) {
    final isLike = _swipeDirection > 0;
    final isPass = _swipeDirection < 0;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLike 
                ? Colors.green.withOpacity(opacity * 0.8)
                : Colors.red.withOpacity(opacity * 0.8),
            width: 4,
          ),
        ),
        child: Center(
          child: Transform.rotate(
            angle: isLike ? -0.3 : 0.3,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isLike ? Colors.green : Colors.red).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLike ? Icons.favorite : Icons.close,
                size: 100,
                color: (isLike ? Colors.green : Colors.red).withOpacity(opacity),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy SwipeableCard for backward compatibility
class SwipeableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
  });

  @override
  Widget build(BuildContext context) {
    return TinderSwipeCard(
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      onSwipeUp: onSwipeUp,
      child: child,
    );
  }
}

/// Animated card with parallax effect
class ParallaxCard extends StatefulWidget {
  final Widget child;
  final double depth;

  const ParallaxCard({
    super.key,
    required this.child,
    this.depth = 20,
  });

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final size = MediaQuery.of(context).size;
        final x = (event.position.dx - size.width / 2) / size.width;
        final y = (event.position.dy - size.height / 2) / size.height;

        setState(() {
          _offset = Offset(x * widget.depth, y * widget.depth);
        });
      },
      onExit: (event) {
        setState(() {
          _offset = Offset.zero;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_offset.dy * 0.01)
          ..rotateY(-_offset.dx * 0.01),
        child: widget.child,
      ),
    );
  }
}

/// Glowing card effect
class GlowingCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;

  const GlowingCard({
    super.key,
    required this.child,
    this.glowColor = Colors.blue,
    this.glowRadius = 20,
  });

  @override
  State<GlowingCard> createState() => _GlowingCardState();
}

class _GlowingCardState extends State<GlowingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_animation.value * 0.5),
                blurRadius: widget.glowRadius * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

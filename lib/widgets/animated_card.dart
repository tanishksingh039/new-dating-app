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

/// Animated profile card with swipe gestures
class SwipeableCard extends StatefulWidget {
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
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.dx > threshold) {
      // Swipe right
      _animateCardOff(const Offset(2, 0));
      widget.onSwipeRight?.call();
    } else if (_dragOffset.dx < -threshold) {
      // Swipe left
      _animateCardOff(const Offset(-2, 0));
      widget.onSwipeLeft?.call();
    } else if (_dragOffset.dy < -threshold) {
      // Swipe up
      _animateCardOff(const Offset(0, -2));
      widget.onSwipeUp?.call();
    } else {
      // Return to center
      _resetCard();
    }
  }

  void _animateCardOff(Offset endOffset) {
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(
        endOffset.dx * MediaQuery.of(context).size.width,
        endOffset.dy * MediaQuery.of(context).size.height,
      ),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward(from: 0).then((_) {
      setState(() => _dragOffset = Offset.zero);
      _controller.reset();
    });
  }

  void _resetCard() {
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward(from: 0).then((_) {
      setState(() => _dragOffset = Offset.zero);
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final offset = _isDragging ? _dragOffset : _animation.value;
    final rotation = offset.dx / 1000;
    final opacity = 1 - (offset.distance / 500).clamp(0.0, 0.5);

    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: opacity,
            child: widget.child,
          ),
        ),
      ),
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

  void _handlePointerMove(PointerMoveEvent event) {
    final size = MediaQuery.of(context).size;
    final x = (event.position.dx - size.width / 2) / size.width;
    final y = (event.position.dy - size.height / 2) / size.height;

    setState(() {
      _offset = Offset(x * widget.depth, y * widget.depth);
    });
  }

  void _handlePointerExit(PointerExitEvent event) {
    setState(() {
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _handlePointerMove(event as PointerMoveEvent),
      onExit: _handlePointerExit,
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

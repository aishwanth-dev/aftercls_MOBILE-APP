import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:campus_pulse/models/post.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/theme.dart';

class SwipeCard extends StatefulWidget {
  final Post post;
  final User? user;
  final Function(String postId, bool isFire) onSwipe;
  final bool isBackground;

  const SwipeCard({
    super.key,
    required this.post,
    this.user,
    required this.onSwipe,
    this.isBackground = false,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: SwipzeeAnimations.mediumAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: SwipzeeAnimations.cardTransition,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: SwipzeeAnimations.swipeCurve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: SwipzeeAnimations.cardTransition,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onSwipeLeft() {
    _animateSwipe(-15, () {
      widget.onSwipe(widget.post.id, false);
    });
  }

  void _onSwipeRight() {
    _animateSwipe(15, () {
      widget.onSwipe(widget.post.id, true);
    });
  }

  void _animateSwipe(double rotation, VoidCallback onComplete) {
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: rotation,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward().then((_) {
      onComplete();
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.0174533, // Convert to radians
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SwipzeeColors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Post Image - Full Background
                      Positioned.fill(
                        child: (widget.post.imageUrl.isNotEmpty)
                            ? Image.network(
                                widget.post.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    gradient: SwipzeeStyles.fireGradient,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 80,
                                      color: SwipzeeColors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: SwipzeeStyles.fireGradient,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 80,
                                    color: SwipzeeColors.white,
                                  ),
                                ),
                              ),
                      ),

                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Info removed (no avatar/name)

                              const Spacer(),

                              // Challenge Tag (Bottom Left)
                              if (widget.post.challengeTag != null &&
                                  widget.post.challengeTag!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        SwipzeeColors.softPink.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '#${widget.post.challengeTag}',
                                    style:
                                        SwipzeeTypography.labelSmall.copyWith(
                                      color: SwipzeeColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // Action Buttons (Bottom)
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _onSwipeLeft,
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: SwipzeeColors.white
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          border: Border.all(
                                            color: SwipzeeColors.white
                                                .withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.close,
                                              color: SwipzeeColors.white,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Pass',
                                              style: SwipzeeTypography
                                                  .buttonMedium
                                                  .copyWith(
                                                color: SwipzeeColors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _onSwipeRight,
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: SwipzeeStyles.fireGradient,
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color: SwipzeeColors.fireOrange
                                                  .withOpacity(0.4),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department,
                                              color: SwipzeeColors.white,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Fire',
                                              style: SwipzeeTypography
                                                  .buttonMedium
                                                  .copyWith(
                                                color: SwipzeeColors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Fire Count (Top Right) - Positioned separately
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: SwipzeeColors.fireOrange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: SwipzeeColors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.post.firesCount}',
                                style: SwipzeeTypography.labelMedium.copyWith(
                                  color: SwipzeeColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Swipe Card Stack Widget
class SwipeCardStack extends StatelessWidget {
  final List<Post> posts;
  final List<User> users;
  final Function(String postId, bool isFire) onSwipe;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const SwipeCardStack({
    super.key,
    required this.posts,
    required this.users,
    required this.onSwipe,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    // Don't render CardSwiper if there are no posts
    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }

    return CardSwiper(
      cardsCount: posts.length,
      numberOfCardsDisplayed:
          posts.length > 0 ? (posts.length < 3 ? posts.length : 3) : 1,
      onSwipe: (previousIndex, currentIndex, direction) {
        if (previousIndex != null && previousIndex < posts.length) {
          final post = posts[previousIndex];
          final isFire = direction == CardSwiperDirection.right;
          onSwipe(post.id, isFire);

          if (isFire) {
            onSwipeRight?.call();
          } else {
            onSwipeLeft?.call();
          }
        }
      },
      cardBuilder: (context, index) {
        if (index >= posts.length) return const SizedBox.shrink();

        final post = posts[index];
        final user = users.firstWhere(
          (u) => u.id == post.userId,
          orElse: () => User(
            id: '',
            email: '',
            nickname: 'Unknown',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return SwipeCard(
          post: post,
          user: user,
          onSwipe: onSwipe,
        );
      },
      // Animation settings
      duration: const Duration(milliseconds: 300),
      threshold: 80,
      isDisabled: false,
      scale: 0.9,
      maxAngle: 15,
      isLoop: false,
    );
  }
}

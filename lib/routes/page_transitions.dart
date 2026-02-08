import 'package:flutter/material.dart';

/// Enum representing the direction of the page slide transition.
enum PageTransitionDirection {
  /// Slide from left (new page enters from the left)
  left,

  /// Slide from right (new page enters from the right) — default
  right,

  /// Slide from bottom (new page enters from the bottom)
  up,

  /// Slide from top (new page enters from the top)
  down,
}

/// A custom [PageRouteBuilder] that provides smooth slide transitions
/// in any of the four cardinal directions.
///
/// Example usage:
/// ```dart
/// Navigator.push(context, SlidePageRoute(
///   page: ProductDetailScreen(),
///   direction: PageTransitionDirection.right,
/// ));
/// ```
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  /// The destination page widget.
  final Widget page;

  /// The direction from which the page slides in.
  /// Defaults to [PageTransitionDirection.right].
  final PageTransitionDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = PageTransitionDirection.right,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Offset begin = _getBeginOffset(direction);
            const Offset end = Offset.zero;

            final tween = Tween<Offset>(begin: begin, end: end).chain(
              CurveTween(curve: Curves.easeInOutCubic),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );

  /// Returns the starting [Offset] for the slide animation based on the
  /// given [direction].
  static Offset _getBeginOffset(PageTransitionDirection direction) {
    switch (direction) {
      case PageTransitionDirection.left:
        return const Offset(-1.0, 0.0); // Enters from the left
      case PageTransitionDirection.right:
        return const Offset(1.0, 0.0); // Enters from the right
      case PageTransitionDirection.up:
        return const Offset(0.0, 1.0); // Enters from the bottom
      case PageTransitionDirection.down:
        return const Offset(0.0, -1.0); // Enters from the top
    }
  }
}

import 'package:flutter/cupertino.dart';

import '../../types/interaction_notification.dart';

/// A universal wrapper that silences parent liquid-stretch container
/// interactions for its [child].
///
/// Wrap any interactive widget (buttons, switches, list tiles) in
/// [GlassInteractionSilence] to dispatch an [InteractionNotification] on
/// pointer down, preventing enclosing liquid-stretch surfaces (such as
/// `GlassModalSheet` or legacy `GlassSheet` with
/// `suppressInteractionOnChildren: true`) from scaling or glowing when the
/// child is tapped.
class GlassInteractionSilence extends StatelessWidget {
  /// The widget that should silence parent stretch/glow interactions.
  final Widget child;

  /// Creates a [GlassInteractionSilence].
  const GlassInteractionSilence({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        InteractionNotification(event).dispatch(context);
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

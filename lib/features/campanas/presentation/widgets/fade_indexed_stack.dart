import 'package:flutter/material.dart';

/// Pestañas de la campaña: muestra solo la elegida y la hace aparecer con un
/// fundido corto, subiendo unos pocos píxeles. Las demás quedan vivas pero
/// ocultas (sin animar ni pintar), así nunca se ven dos pantallas encimadas.
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration, value: 1);
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(begin: const Offset(0, 0.015), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (final (i, child) in widget.children.indexed)
          // Misma estructura para todas: cambiarla haría perder el estado de la rama.
          TickerMode(
            enabled: i == widget.index,
            child: SlideTransition(
              position: i == widget.index ? _slide : const AlwaysStoppedAnimation(Offset.zero),
              child: FadeTransition(opacity: i == widget.index ? _opacity : kAlwaysCompleteAnimation, child: child),
            ),
          ),
      ],
    );
  }
}

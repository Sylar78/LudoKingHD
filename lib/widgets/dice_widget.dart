import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final VoidCallback? onRoll;
  final bool enabled;

  const DiceWidget({
    super.key,
    required this.value,
    required this.isRolling,
    this.onRoll,
    this.enabled = true,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shadowCtrl;

  @override
  void initState() {
    super.initState();
    _shadowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.isRolling) {
      _shadowCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !_shadowCtrl.isAnimating) {
      _shadowCtrl.repeat(reverse: true);
    } else if (!widget.isRolling && _shadowCtrl.isAnimating) {
      _shadowCtrl.stop();
      _shadowCtrl.value = 0.0;
    }
  }

  @override
  void dispose() {
    _shadowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !widget.isRolling;
    final shadowPulse = Curves.easeInOut.transform(_shadowCtrl.value);
    final double dynamicBlur =
      widget.isRolling ? 10.0 + shadowPulse * 12.0 : 14.0;
    final double dynamicY =
      widget.isRolling ? 4.0 + shadowPulse * 8.0 : 8.0;
    final double dynamicSpread =
      widget.isRolling ? -1.5 + shadowPulse * 0.5 : 0.0;

    return GestureDetector(
      onTap: enabled ? widget.onRoll : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled
                ? const [Color(0xFFFFFEFD), Color(0xFFD8DADF)]
                : const [Color(0xFFE7E7E7), Color(0xFFBBBBBB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.33),
              blurRadius: dynamicBlur,
              spreadRadius: dynamicSpread,
              offset: Offset(2.0, dynamicY),
            ),
            if (enabled)
              BoxShadow(
                color: const Color(0xFFFFD34F).withOpacity(0.25),
                blurRadius: 14,
                spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: enabled ? const Color(0xFFFFC840) : const Color(0xFF9A9A9A),
            width: 2.2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.6),
                        Colors.transparent,
                        Colors.black.withOpacity(0.08),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: widget.isRolling
                  ? _RollingDice()
                  : _DiceFace(value: widget.value),
            ),
          ],
        ),
      )
          .animate(target: widget.isRolling ? 1 : 0)
          .shake(hz: 9, rotation: 0.0),
    );
  }
}

class _RollingDice extends StatefulWidget {
  @override
  State<_RollingDice> createState() => _RollingDiceState();
}

class _RollingDiceState extends State<_RollingDice>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _val = 6;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 92))
      ..addListener(() {
        if (_ctrl.isCompleted) {
          setState(() => _val = ((_val + 2) % 6) + 1);
          _ctrl.reset();
          _ctrl.forward();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Center(child: _DiceFace(value: _val));
}

class _DiceFace extends StatelessWidget {
  final int value;
  const _DiceFace({required this.value});

  // Standard dice 3×3 grid layout – false = invisible dot (transparent placeholder)
  static const _dots = {
    1: [[false, false, false], [false, true,  false], [false, false, false]],
    2: [[true,  false, false], [false, false, false], [false, false, true ]],
    3: [[true,  false, false], [false, true,  false], [false, false, true ]],
    4: [[true,  false, true ], [false, false, false], [true,  false, true ]],
    5: [[true,  false, true ], [false, true,  false], [true,  false, true ]],
    6: [[true,  false, true ], [true,  false, true ], [true,  false, true ]],
  };

  @override
  Widget build(BuildContext context) {
    final dots = _dots[value]!;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dots.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((filled) {
              return Container(
                width: 9.5,
                height: 9.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: filled
                      ? const RadialGradient(
                          center: Alignment(-0.2, -0.2),
                          colors: [Color(0xFF2A2A2A), Color(0xFF090909)],
                        )
                      : null,
                  color: filled ? null : Colors.transparent,
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 2.2,
                            offset: const Offset(0.4, 1.2),
                          ),
                        ]
                      : null,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

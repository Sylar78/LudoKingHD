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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled && !widget.isRolling ? widget.onRoll : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: widget.enabled ? Colors.white : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
          border: Border.all(
            color: widget.enabled
                ? const Color(0xFF7C4DFF)
                : Colors.grey.shade400,
            width: 2.5,
          ),
        ),
        child: widget.isRolling
            ? _RollingDice()
            : Center(child: _DiceFace(value: widget.value)),
      )
          .animate(target: widget.isRolling ? 1 : 0)
          .shake(hz: 8, rotation: 0.1),
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
  int _val = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100))
      ..addListener(() {
        if (_ctrl.isCompleted) {
          setState(() => _val = (_val % 6) + 1);
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
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dots.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((filled) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? const Color(0xFF7C4DFF)
                      : Colors.transparent,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

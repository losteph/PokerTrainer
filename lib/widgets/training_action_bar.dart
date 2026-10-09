import 'package:flutter/material.dart';
import '../core/controllers/game_controller.dart';

class TrainingActionBar extends StatelessWidget {
  final void Function(TrainingAction action) onAction;

  const TrainingActionBar({
    super.key,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'FOLD',
            color: Colors.red.shade700,
            onPressed: () => onAction(TrainingAction.fold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionButton(
            label: 'CALL',
            color: Colors.green.shade700,
            onPressed: () => onAction(TrainingAction.call),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
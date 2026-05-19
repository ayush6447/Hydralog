import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IntakeButton extends StatelessWidget {
  final String label;
  final int amount;
  final VoidCallback onTap;

  const IntakeButton({
    super.key,
    required this.label,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.tealAccent.withOpacity(0.3),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.cyanAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_drink, color: Colors.black),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

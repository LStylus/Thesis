import 'package:flutter/material.dart';

class RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color fillColor;
  final Color iconColor;

  const RoundActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.fillColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: fillColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}

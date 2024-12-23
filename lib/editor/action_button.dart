import "package:flutter/material.dart";

class ActionButton extends StatelessWidget {
  const ActionButton(
      {super.key,
      required this.tooltip,
      required this.height,
      required this.width,
      required this.onPressed,
      required this.icon});

  final double height;
  final double width;
  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        child: Icon(icon, key: ValueKey(icon.codePoint)),
      ),
    );
  }
}

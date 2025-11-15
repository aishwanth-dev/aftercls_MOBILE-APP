import 'package:flutter/material.dart';

class ReactionButton extends StatelessWidget {
  final String emojiPath;
  final bool isSelected;
  final VoidCallback onTap;

  const ReactionButton({
    Key? key,
    required this.emojiPath,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset(
          emojiPath,
          width: 32,
          height: 32,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:taskie/core/constants/app_enums.dart';

class PriorityBadge extends StatelessWidget {
  final Priority priority;
  final bool showLabel;
  const PriorityBadge({super.key, required this.priority, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final color = Color(priority.colorValue);
    if(!showLabel){
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: color
            ),
          )
        ],
      ),
    );
  }
}
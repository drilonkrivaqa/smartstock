import 'package:flutter/material.dart';

import '../models/stock_movement.dart';

class StockMovementTile extends StatelessWidget {
  const StockMovementTile({super.key, required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final totalChange = movement.lines.fold<double>(
      0,
      (sum, line) => sum + line.quantity,
    );
    final isPositive = totalChange >= 0;
    final quantityText = totalChange >= 0
        ? '+${totalChange.toStringAsFixed(2)} units'
        : '${totalChange.toStringAsFixed(2)} units';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isPositive ? Colors.green.shade100 : Colors.red.shade100,
        child: Icon(
          isPositive ? Icons.arrow_downward : Icons.arrow_upward,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
      title: Text(quantityText),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(movement.type),
          Text(
            movement.date.toLocal().toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (movement.note != null && movement.note!.isNotEmpty)
            Text(
              movement.note!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

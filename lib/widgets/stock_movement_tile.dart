import 'package:flutter/material.dart';

import '../models/stock_movement.dart';

class StockMovementTile extends StatelessWidget {
  const StockMovementTile({super.key, required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final isPositive = movement.change >= 0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isPositive ? Colors.green.shade100 : Colors.red.shade100,
        child: Icon(
          isPositive ? Icons.arrow_downward : Icons.arrow_upward,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
      title: Text('${movement.change > 0 ? '+' : ''}${movement.change} units'),
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

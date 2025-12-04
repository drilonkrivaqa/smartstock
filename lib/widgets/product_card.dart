import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.highlightLowStock,
    required this.onTap,
  });

  final Product product;
  final bool highlightLowStock;
  final VoidCallback onTap;

  Color _statusColor(ColorScheme scheme) {
    if (product.quantity == 0) {
      return Colors.red.shade400;
    }
    if (product.quantity <= product.minQuantity && highlightLowStock) {
      return Colors.orange.shade400;
    }
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 60,
                decoration: BoxDecoration(
                  color: _statusColor(colorScheme),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 18, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('Qty: ${product.quantity}'),
                      ],
                    ),
                    if (product.location != null && product.location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(product.location!),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

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
    if (product.expiryDate != null) {
      final days = product.expiryDate!
          .difference(DateTime.now())
          .inDays;
      if (days < 7) {
        return Colors.red.shade400;
      }
      if (days < 30) {
        return Colors.orange.shade400;
      }
      return Colors.green.shade600;
    }
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
                    if (product.expiryDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 18,
                              color: _statusColor(colorScheme),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _expiryLabel(),
                              style: TextStyle(
                                color: _statusColor(colorScheme),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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

  String _expiryLabel() {
    if (product.expiryDate == null) return '';
    final now = DateTime.now();
    final difference = product.expiryDate!.difference(now).inDays;
    if (difference < 0) {
      return 'Expired';
    }
    if (difference == 0) {
      return 'Expires today';
    }
    if (difference == 1) {
      return 'Expires in 1 day';
    }
    return 'Expires in $difference days';
  }
}

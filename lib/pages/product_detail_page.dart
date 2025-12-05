import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/product.dart';
import '../models/stock_movement.dart';
import '../services/hive_service.dart';
import '../services/product_service.dart';
import '../services/settings_service.dart';
import '../widgets/product_card.dart';
import '../widgets/stock_movement_tile.dart';
import 'product_form_page.dart';
import 'stock_adjustment_dialog.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.productService,
    required this.settingsController,
  });

  final int productId;
  final ProductService productService;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final productsBox = Hive.box<Product>(HiveService.productsBox);
    final movementsBox = Hive.box<StockMovement>(HiveService.movementsBox);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final product = productsBox.values
                  .firstWhere((element) => element.id == productId);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductFormPage(
                    productService: productService,
                    existing: product,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder(
            valueListenable: productsBox.listenable(),
            builder: (context, Box<Product> box, _) {
              final product = box.values
                  .firstWhere((element) => element.id == productId);
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.photoPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(product.photoPath!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (product.photoPath != null) const SizedBox(height: 12),
                    ProductCard(
                      product: product,
                      highlightLowStock: settingsController.highlightLowStock,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Quantity',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      product.quantity.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                FilledButton.icon(
                                  onPressed: () async {
                                    final result = await showModalBottomSheet<
                                        StockAdjustmentResult>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => StockAdjustmentDialog(
                                        product: product,
                                      ),
                                    );
                                    if (result != null) {
                                      await productService.adjustStock(
                                        product: product,
                                        change: result.change,
                                        type: result.type,
                                        note: result.note,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.edit_note),
                                  label: const Text('Adjust stock'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(label: 'SKU', value: product.sku ?? '-'),
                            _InfoRow(
                                label: 'Barcode', value: product.barcode ?? '-'),
                            _InfoRow(
                                label: 'Category', value: product.category ?? '-'),
                            _InfoRow(
                                label: 'Location', value: product.location ?? '-'),
                            _InfoRow(
                              label: 'Purchase price',
                              value: product.purchasePrice != null
                                  ? product.purchasePrice!.toStringAsFixed(2)
                                  : '-',
                            ),
                            _InfoRow(
                          label: 'Sale price',
                          value: product.salePrice != null
                              ? product.salePrice!.toStringAsFixed(2)
                              : '-',
                        ),
                        _InfoRow(
                          label: 'Expiry',
                          value: _expiryDescription(product),
                        ),
                        _InfoRow(
                          label: 'Minimum qty',
                          value: product.minQuantity.toString(),
                        ),
                        if (product.notes != null && product.notes!.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 4),
                                child: Text(
                                  product.notes!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Recent movements',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder(
                      valueListenable: movementsBox.listenable(),
                      builder: (context, Box<StockMovement> _, __) {
                        final list =
                            productService.movementsForProduct(productId);
                        if (list.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No movements recorded yet. Adjust stock or complete a sale to see history.',
                            ),
                          );
                        }
                        return Column(
                          children: list
                              .map((movement) => StockMovementTile(
                                    movement: movement,
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

String _expiryDescription(Product product) {
  if (product.expiryDate == null) return '-';
  final date = product.expiryDate!;
  final twoDigits = (int value) => value.toString().padLeft(2, '0');
  final formatted = '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
  final days = date.difference(DateTime.now()).inDays;
  if (days < 0) return '$formatted (Expired)';
  if (days == 0) return '$formatted (Expires today)';
  if (days == 1) return '$formatted (Expires in 1 day)';
  return '$formatted (Expires in $days days)';
}

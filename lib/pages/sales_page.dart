import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key, required this.saleService, required this.productService});

  final SaleService saleService;
  final ProductService productService;

  @override
  Widget build(BuildContext context) {
    final sales = saleService.getSales();
    return Scaffold(
      appBar: AppBar(title: const Text('Sales history')),
      body: sales.isEmpty
          ? const Center(
              child: Text('No sales recorded yet. Complete a checkout to see it here.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sales.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sale = sales[index];
                return _SaleCard(
                  sale: sale,
                  productService: productService,
                );
              },
            ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale, required this.productService});

  final Sale sale;
  final ProductService productService;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sale #${sale.id}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(_formatDate(sale.date)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${sale.totalItems} item(s)'),
            Text('Total: ${sale.totalValue.toStringAsFixed(2)}'),
            if (sale.customerName != null && sale.customerName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Customer: ${sale.customerName}'),
              ),
            const Divider(),
            ...sale.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_productName(item.productId)),
                    Text('${item.quantity} × ${item.unitPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  String _productName(int id) {
    final product = productService.findById(id);
    if (product == null) return 'Product #$id';
    return product.name;
  }
}

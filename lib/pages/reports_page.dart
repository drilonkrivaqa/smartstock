import 'package:flutter/material.dart';

import '../services/product_service.dart';
import '../services/sale_service.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, required this.productService, required this.saleService});

  final ProductService productService;
  final SaleService saleService;

  @override
  Widget build(BuildContext context) {
    final products = productService.getProducts();
    final totalUnits = products.fold<int>(0, (sum, p) => sum + p.quantity);
    final totalValue = products.fold<double>(0, (sum, p) {
      if (p.purchasePrice == null) return sum;
      return sum + (p.purchasePrice! * p.quantity);
    });
    final lowStock = products.where((p) => p.quantity <= p.minQuantity).toList();
    final expiringSoon = products
        .where((p) => p.expiryDate != null &&
            p.expiryDate!.isBefore(DateTime.now().add(const Duration(days: 7))))
        .toList();
    final todaySales = saleService.totalSalesForDay(DateTime.now());
    final weekSales = saleService.totalSalesForRange(DateTime.now().subtract(const Duration(days: 7)));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReportCard(
            title: 'Stock overview',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Products: ${products.length}'),
                Text('Total units: $totalUnits'),
                Text('Stock value: ${totalValue.toStringAsFixed(2)}'),
              ],
            ),
          ),
          _ReportCard(
            title: 'Low stock',
            child: lowStock.isEmpty
                ? const Text('No low stock items. Great job!')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lowStock
                        .map((p) => Text('${p.name} — Qty: ${p.quantity}'))
                        .toList(),
                  ),
          ),
          _ReportCard(
            title: 'Expiring soon',
            child: expiringSoon.isEmpty
                ? const Text('No expiring items in the next 7 days.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: expiringSoon
                        .map((p) => Text('${p.name} — ${p.expiryDate}'))
                        .toList(),
                  ),
          ),
          _ReportCard(
            title: 'Sales overview',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today: ${todaySales.toStringAsFixed(2)}'),
                Text('Last 7 days: ${weekSales.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../services/hive_service.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({
    super.key,
    required this.productService,
    required this.saleService,
  });

  final ProductService productService;
  final SaleService saleService;

  @override
  Widget build(BuildContext context) {
    final productsBox = Hive.box<Product>(HiveService.productsBox);
    final salesBox = Hive.box<Sale>(HiveService.salesBox);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder(
            valueListenable: productsBox.listenable(),
            builder: (context, Box<Product> _, __) {
              final products = productService.getProducts();
              final totalStockUnits = products.fold<int>(0, (sum, p) => sum + p.quantity);
              final totalStockValue = products.fold<double>(
                0,
                (sum, p) => sum + (p.purchasePrice ?? 0) * p.quantity,
              );
              final lowStock = products
                  .where((p) => p.quantity <= p.minQuantity)
                  .toList();
              final expiringSoon = products
                  .where(
                    (p) => p.expiryDate != null &&
                        p.expiryDate!.isBefore(
                          DateTime.now().add(const Duration(days: 14)),
                        ),
                  )
                  .toList();
              return ValueListenableBuilder(
                valueListenable: salesBox.listenable(),
                builder: (context, Box<Sale> __, ___) {
                  final today = DateTime.now();
                  final startOfDay = DateTime(today.year, today.month, today.day);
                  final startOfWeek = startOfDay.subtract(Duration(days: today.weekday - 1));
                  final salesToday = saleService.salesTotalFor(
                    startOfDay.subtract(const Duration(seconds: 1)),
                    startOfDay.add(const Duration(days: 1)),
                  );
                  final salesWeek = saleService.salesTotalFor(
                    startOfWeek.subtract(const Duration(seconds: 1)),
                    startOfDay.add(const Duration(days: 1)),
                  );
                  return ListView(
                    children: [
                      _ReportCard(
                        title: 'Stock overview',
                        icon: Icons.inventory_2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Products: ${products.length}'),
                            Text('Units in stock: $totalStockUnits'),
                            Text('Stock value: ${totalStockValue.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      _ReportCard(
                        title: 'Low stock',
                        icon: Icons.warning_amber,
                        child: lowStock.isEmpty
                            ? const Text('All items are above the minimum levels.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: lowStock
                                    .map(
                                      (p) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text('${p.name} (qty: ${p.quantity})'),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      _ReportCard(
                        title: 'Expiring soon',
                        icon: Icons.schedule,
                        child: expiringSoon.isEmpty
                            ? const Text('No products expiring in the next 2 weeks.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: expiringSoon
                                    .map(
                                      (p) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text(
                                          '${p.name} - expires ${MaterialLocalizations.of(context).formatMediumDate(p.expiryDate!)}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      _ReportCard(
                        title: 'Sales overview',
                        icon: Icons.point_of_sale,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Today: ${salesToday.toStringAsFixed(2)}'),
                            Text('This week: ${salesWeek.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

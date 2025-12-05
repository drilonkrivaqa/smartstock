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
                  final startOfMonth = DateTime(today.year, today.month, 1);
                  final last30Days = startOfDay.subtract(const Duration(days: 30));
                  final last60Days = startOfDay.subtract(const Duration(days: 60));
                  final salesToday = saleService.salesTotalFor(
                    startOfDay.subtract(const Duration(seconds: 1)),
                    startOfDay.add(const Duration(days: 1)),
                  );
                  final salesWeek = saleService.salesTotalFor(
                    startOfWeek.subtract(const Duration(seconds: 1)),
                    startOfDay.add(const Duration(days: 1)),
                  );
                  final salesMonth = saleService.salesTotalFor(
                    startOfMonth.subtract(const Duration(seconds: 1)),
                    startOfDay.add(const Duration(days: 1)),
                  );
                  final profit30Days = saleService.grossProfitFor(
                    last30Days,
                    startOfDay.add(const Duration(days: 1)),
                  );
              final revenue30Days = saleService.salesTotalFor(
                last30Days.subtract(const Duration(seconds: 1)),
                    startOfDay.add(const Duration(days: 1)),
                  );
                  final margin30Days = revenue30Days == 0
                      ? 0
                      : (profit30Days / revenue30Days) * 100;
                  final soldLast30Days = saleService.quantitySoldSince(last30Days);
                  final soldLast60Days = saleService.quantitySoldSince(last60Days);
                  final topSellers = soldLast30Days.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final slowMovers = products
                      .where((p) => !soldLast60Days.keys.contains(p.id))
                      .toList()
                    ..sort((a, b) => a.name.compareTo(b.name));
                  final uniqueCustomers = saleService.uniqueCustomersCount();
                  final repeatCustomers = saleService
                      .getSales()
                      .where((sale) => sale.customerName != null && sale.customerName!.isNotEmpty)
                      .fold<Map<String, int>>({}, (map, sale) {
                    final name = sale.customerName!.trim();
                    map.update(name, (value) => value + 1, ifAbsent: () => 1);
                    return map;
                  });
                  final reorderSuggestions = products
                      .where((p) => p.quantity < p.minQuantity)
                      .map(
                        (p) => _ReorderSuggestion(
                          product: p,
                          recommendedQuantity:
                              (p.minQuantity - p.quantity) + (p.minQuantity * 0.2).ceil(),
                        ),
                      )
                      .toList()
                    ..sort(
                      (a, b) => b.recommendedQuantity.compareTo(a.recommendedQuantity),
                    );
                  final demand30Days = soldLast30Days.values.fold<int>(0, (sum, qty) => sum + qty);
                  final averageDailyDemand = demand30Days / 30;
                  final inventoryCoverageDays = averageDailyDemand == 0
                      ? null
                      : (totalStockUnits / averageDailyDemand).ceil();
                  final salesLast30Days = saleService.getSalesInRange(
                    last30Days,
                    startOfDay.add(const Duration(days: 1)),
                  );
                  final categoryMix = <String, double>{};
                  final productLookup = saleService.productLookup();
                  for (final sale in salesLast30Days) {
                    for (final item in sale.items) {
                      final category =
                          (productLookup[item.productId]?.category ?? 'Uncategorized').trim();
                      categoryMix.update(
                        category.isEmpty ? 'Uncategorized' : category,
                        (value) =>
                            value + (item.quantity * item.unitPrice),
                        ifAbsent: () => item.quantity * item.unitPrice,
                      );
                    }
                  }
                  final totalCategoryRevenue =
                      categoryMix.values.fold<double>(0, (sum, value) => sum + value);
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
                            if (inventoryCoverageDays != null)
                              Text('Coverage: ~$inventoryCoverageDays days at current pace'),
                          ],
                        ),
                      ),
                      if (reorderSuggestions.isNotEmpty)
                        _ReportCard(
                          title: 'Reorder suggestions',
                          icon: Icons.local_shipping,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: reorderSuggestions.take(5).map((suggestion) {
                              final product = suggestion.product;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  '${product.name} • Order ${suggestion.recommendedQuantity} to reach safety stock',
                                ),
                              );
                            }).toList(),
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
                            Text('This month: ${salesMonth.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      _ReportCard(
                        title: 'Top sellers (last 30 days)',
                        icon: Icons.rocket_launch,
                        child: topSellers.isEmpty
                            ? const Text('No sales recorded in the last 30 days.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: topSellers.take(5).map((entry) {
                                  final product =
                                      productService.findById(entry.key)?.name ?? 'Unknown';
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text('$product • ${entry.value} sold'),
                                  );
                                }).toList(),
                              ),
                      ),
                      _ReportCard(
                        title: 'Slow movers (no sales in 60 days)',
                        icon: Icons.hourglass_bottom,
                        child: slowMovers.isEmpty
                            ? const Text('All products have recent activity.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: slowMovers
                                    .map(
                                      (p) => Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 2),
                                        child: Text('${p.name} (qty: ${p.quantity})'),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      _ReportCard(
                        title: 'Profitability (last 30 days)',
                        icon: Icons.monetization_on,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Revenue: ${revenue30Days.toStringAsFixed(2)}'),
                            Text('Gross profit: ${profit30Days.toStringAsFixed(2)}'),
                            Text('Margin: ${margin30Days.toStringAsFixed(1)}%'),
                            Text('Avg daily revenue (30d): ${(revenue30Days / 30).toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      _ReportCard(
                        title: 'Customer insights',
                        icon: Icons.people,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unique customers: $uniqueCustomers'),
                            Text(
                              'Repeat customers: ${repeatCustomers.values.where((count) => count > 1).length}',
                            ),
                          ],
                        ),
                      ),
                      _ReportCard(
                        title: 'Category performance (last 30 days)',
                        icon: Icons.pie_chart,
                        child: categoryMix.isEmpty
                            ? const Text('No sales data in the last 30 days yet.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: categoryMix.entries.map((entry) {
                                  final share = totalCategoryRevenue == 0
                                      ? 0
                                      : (entry.value / totalCategoryRevenue) * 100;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Text(
                                      '${entry.key}: ${entry.value.toStringAsFixed(2)} (${share.toStringAsFixed(1)}%)',
                                    ),
                                  );
                                }).toList(),
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

class _ReorderSuggestion {
  _ReorderSuggestion({required this.product, required this.recommendedQuantity});

  final Product product;
  final int recommendedQuantity;
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

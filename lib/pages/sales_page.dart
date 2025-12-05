import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sale.dart';
import '../services/hive_service.dart';
import '../services/sale_service.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({
    super.key,
    required this.saleService,
  });

  final SaleService saleService;

  @override
  Widget build(BuildContext context) {
    final salesBox = Hive.box<Sale>(HiveService.salesBox);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales history'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder(
            valueListenable: salesBox.listenable(),
            builder: (context, Box<Sale> _, __) {
              final sales = saleService.getSales();
              final productLookup = saleService.productLookup();
              if (sales.isEmpty) {
                return const Center(
                  child: Text('No sales recorded yet. Complete a checkout to see it here.'),
                );
              }
              return ListView.separated(
                itemCount: sales.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text(
                        'Sale on ${MaterialLocalizations.of(context).formatMediumDate(sale.date)}',
                      ),
                      subtitle: Text(
                        '${sale.totalItems} items • Total ${sale.totalValue.toStringAsFixed(2)}' +
                            (sale.customerName != null && sale.customerName!.isNotEmpty
                                ? ' • ${sale.customerName}'
                                : ''),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final item in sale.items)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    productLookup[item.productId]?.name ?? 'Unknown product',
                                  ),
                                  subtitle: Text('Qty: ${item.quantity} x ${item.unitPrice.toStringAsFixed(2)}'),
                                  trailing: Text(
                                    (item.quantity * item.unitPrice).toStringAsFixed(2),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (sale.note != null && sale.note!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('Note: ${sale.note}'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

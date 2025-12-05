import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/sale.dart';
import '../services/hive_service.dart';
import '../services/sale_service.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({
    super.key,
    required this.saleService,
  });

  final SaleService saleService;

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final salesBox = Hive.box<Sale>(HiveService.salesBox);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales history'),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            tooltip: 'Export sales to CSV',
            onPressed: _exporting ? null : _exportSales,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder(
            valueListenable: salesBox.listenable(),
            builder: (context, Box<Sale> _, __) {
              final sales = widget.saleService.getSales();
              final productLookup = widget.saleService.productLookup();
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

  Future<void> _exportSales() async {
    setState(() => _exporting = true);
    try {
      final sales = widget.saleService.getSales();
      if (sales.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No sales to export yet.')),
          );
        }
        return;
      }
      final productLookup = widget.saleService.productLookup();
      final rows = <List<String>>[
        ['Date', 'Customer', 'Product', 'Quantity', 'Unit price', 'Line total', 'Note'],
      ];
      for (final sale in sales) {
        for (final item in sale.items) {
          final productName = productLookup[item.productId]?.name ?? 'Unknown product';
          final lineTotal = (item.quantity * item.unitPrice).toStringAsFixed(2);
          rows.add([
            MaterialLocalizations.of(context).formatMediumDate(sale.date),
            sale.customerName ?? '-',
            productName,
            item.quantity.toString(),
            item.unitPrice.toStringAsFixed(2),
            lineTotal,
            sale.note ?? '-',
          ]);
        }
      }
      final csvData = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/sales_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csvData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sales exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export sales: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }
}

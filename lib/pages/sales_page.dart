import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart'; // or the correct product model file

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
  _DatePreset _preset = _DatePreset.last30Days;
  DateTimeRange? _customRange;
  String _searchQuery = '';
  double _minTotal = 0;

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
              final filteredSales = _applyFilters(sales, productLookup);
              if (sales.isEmpty) {
                return const Center(
                  child: Text('No sales recorded yet. Complete a checkout to see it here.'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FiltersBar(
                    preset: _preset,
                    onPresetChanged: (preset) => setState(() => _preset = preset),
                    onCustomRangeChanged: (range) => setState(() => _customRange = range),
                    customRange: _customRange,
                    minTotal: _minTotal,
                    onMinTotalChanged: (value) => setState(() => _minTotal = value),
                    searchQuery: _searchQuery,
                    onSearchChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 12),
                  _SalesSummary(sales: filteredSales),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredSales.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty && _minTotal == 0 && _preset == _DatePreset.all
                                  ? 'No sales match the selected range.'
                                  : 'No sales match your filters.',
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredSales.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final sale = filteredSales[index];
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
                                          Row(
                                            children: [
                                              const Icon(Icons.schedule, size: 18),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${MaterialLocalizations.of(context).formatMediumDate(sale.date)} • ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(sale.date))}',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
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
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Sale> _applyFilters(List<Sale> sales, Map<int, Product> productLookup) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;
    switch (_preset) {
      case _DatePreset.today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case _DatePreset.last7Days:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
        end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        break;
      case _DatePreset.last30Days:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
        end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        break;
      case _DatePreset.custom:
        start = _customRange?.start;
        end = _customRange != null
            ? _customRange!.end.add(const Duration(days: 1))
            : null;
        break;
      case _DatePreset.all:
        break;
    }

    final query = _searchQuery.toLowerCase().trim();
    final filtered = sales.where((sale) {
      final inRange = () {
        if (start != null && sale.date.isBefore(start!)) return false;
        if (end != null && !sale.date.isBefore(end!)) return false;
        return true;
      }();

      final matchesQuery = () {
        if (query.isEmpty) return true;
        final customer = (sale.customerName ?? '').toLowerCase();
        final note = (sale.note ?? '').toLowerCase();
        final productMatches = sale.items.any((item) {
          final name = productLookup[item.productId]?.name.toLowerCase() ?? '';
          return name.contains(query);
        });
        return customer.contains(query) || note.contains(query) || productMatches;
      }();

      final meetsValue = sale.totalValue >= _minTotal;
      return inRange && matchesQuery && meetsValue;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> _exportSales() async {
    setState(() => _exporting = true);
    try {
      final sales = _applyFilters(
        widget.saleService.getSales(),
        widget.saleService.productLookup(),
      );
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

class _SalesSummary extends StatelessWidget {
  const _SalesSummary({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final totalRevenue = sales.fold<double>(0, (sum, sale) => sum + sale.totalValue);
    final totalItems = sales.fold<int>(0, (sum, sale) => sum + sale.totalItems);
    final averageTicket = sales.isEmpty ? 0 : totalRevenue / sales.length;
    final averageBasketSize = sales.isEmpty ? 0 : totalItems / sales.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SummaryTile(
              label: 'Revenue',
              value: totalRevenue.toStringAsFixed(2),
              icon: Icons.payments,
            ),
            _SummaryTile(
              label: 'Avg. ticket',
              value: averageTicket.toStringAsFixed(2),
              icon: Icons.receipt_long,
            ),
            _SummaryTile(
              label: 'Avg. items',
              value: averageBasketSize.toStringAsFixed(1),
              icon: Icons.shopping_bag,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.preset,
    required this.onPresetChanged,
    required this.onCustomRangeChanged,
    required this.customRange,
    required this.minTotal,
    required this.onMinTotalChanged,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final _DatePreset preset;
  final ValueChanged<_DatePreset> onPresetChanged;
  final ValueChanged<DateTimeRange?> onCustomRangeChanged;
  final DateTimeRange? customRange;
  final double minTotal;
  final ValueChanged<double> onMinTotalChanged;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in _DatePreset.values)
              ChoiceChip(
                selected: preset == option,
                label: Text(_labelForPreset(option)),
                onSelected: (_) async {
                  onPresetChanged(option);
                  if (option == _DatePreset.custom) {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: customRange,
                    );
                    onCustomRangeChanged(picked);
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (preset == _DatePreset.custom && customRange != null)
          Text(
            'Custom range: ${MaterialLocalizations.of(context).formatMediumDate(customRange!.start)} - ${MaterialLocalizations.of(context).formatMediumDate(customRange!.end)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (preset == _DatePreset.custom) const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: ValueKey('sales-search-$searchQuery'),
                decoration: const InputDecoration(
                  hintText: 'Search by customer, note or product',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Min total'),
                Slider(
                  value: minTotal.clamp(0, 10000),
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  label: minTotal.toStringAsFixed(0),
                  onChanged: onMinTotalChanged,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _labelForPreset(_DatePreset preset) {
    switch (preset) {
      case _DatePreset.today:
        return 'Today';
      case _DatePreset.last7Days:
        return 'Last 7 days';
      case _DatePreset.last30Days:
        return 'Last 30 days';
      case _DatePreset.custom:
        return 'Custom';
      case _DatePreset.all:
        return 'All time';
    }
  }
}

enum _DatePreset { today, last7Days, last30Days, custom, all }

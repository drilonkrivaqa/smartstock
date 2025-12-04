import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';

import '../models/product.dart';
import '../services/hive_service.dart';
import '../services/product_service.dart';
import '../services/settings_service.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';
import 'product_form_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.productService,
    required this.settingsController,
  });

  final ProductService productService;
  final SettingsController settingsController;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = '';
  ProductFilter _filter = ProductFilter.all;

  @override
  Widget build(BuildContext context) {
    final productsBox = Hive.box<Product>(HiveService.productsBox);
    return AnimatedBuilder(
      animation: widget.settingsController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SmartStock'),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan to find product',
                onPressed: _scanToFind,
              ),
              PopupMenuButton<ProductFilter>(
                icon: const Icon(Icons.filter_alt_outlined),
                onSelected: (filter) => setState(() => _filter = filter),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: ProductFilter.all,
                    child: Text('Show all'),
                  ),
                  PopupMenuItem(
                    value: ProductFilter.lowStock,
                    child: Text('Only low stock'),
                  ),
                  PopupMenuItem(
                    value: ProductFilter.outOfStock,
                    child: Text('Only out of stock'),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsPage(
                            settingsController: widget.settingsController,
                          ),
                        ),
                      );
                      break;
                    case 'export':
                      _exportStockReport();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'export',
                    child: Text('Export stock report'),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name, SKU or barcode',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: productsBox.listenable(),
                      builder: (context, Box<Product> box, _) {
                        final products = widget.productService.getProducts(
                          searchQuery: _query,
                          filter: _filter,
                        );
                        if (products.isEmpty) {
                          return const Center(
                            child: Text('No products yet. Tap + to add one.'),
                          );
                        }
                        return ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ProductCard(
                              product: product,
                              highlightLowStock:
                                  widget.settingsController.highlightLowStock,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPage(
                                    productId: product.id,
                                    productService: widget.productService,
                                    settingsController:
                                        widget.settingsController,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add product'),
          ),
        );
      },
    );
  }

  Future<void> _navigateToForm({Product? product, String? barcode}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          productService: widget.productService,
          existing: product,
          prefilledBarcode: barcode,
        ),
      ),
    );
  }

  Future<void> _scanToFind() async {
    final code = await _openScanner();
    if (code == null) return;
    final product = widget.productService.findByBarcode(code);
    if (product != null) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              productId: product.id,
              productService: widget.productService,
              settingsController: widget.settingsController,
            ),
          ),
        );
      }
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Product not found'),
          content: Text('Create a new product for barcode "$code"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToForm(barcode: code);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );
    }
  }

  Future<String?> _openScanner() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.first.rawValue;
              if (barcode != null) {
                Navigator.of(context).pop(barcode);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _exportStockReport() async {
    final products = widget.productService.getProducts();
    final rows = [
      [
        'Product name',
        'SKU',
        'Category',
        'Location',
        'Quantity',
        'Min quantity',
      ],
      ...products.map(
        (p) => [
          p.name,
          p.sku ?? '',
          p.category ?? '',
          p.location ?? '',
          p.quantity.toString(),
          p.minQuantity.toString(),
        ],
      ),
    ];
    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/stock_report_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csvData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved to ${file.path}')),
      );
    }
  }
}

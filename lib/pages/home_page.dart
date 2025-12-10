import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';

import '../models/product.dart';
import '../services/hive_service.dart';
import '../services/product_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../services/sale_service.dart';
import '../services/stock_service.dart';
import 'checkout_page.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';
import 'product_form_page.dart';
import 'settings_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    required this.productService,
    required this.stockService,
    required this.locationService,
    required this.settingsController,
    required this.saleService,
  });

  final ProductService productService;
  final StockService stockService;
  final LocationService locationService;
  final SettingsController settingsController;
  final SaleService saleService;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _query = '';
  ProductFilter _filter = ProductFilter.all;
  bool _inventoryCountMode = false;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productsBox = Hive.box<Product>(HiveService.productsBox);

    return AnimatedBuilder(
      animation: widget.settingsController,
      builder: (context, _) {
        final activeLocation = widget.settingsController.activeLocation;

        return Scaffold(
          appBar: AppBar(
            title: Text('SmartStock – $activeLocation'),
            actions: [
              IconButton(
                icon: const Icon(Icons.point_of_sale),
                tooltip: 'Checkout',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckoutPage(
                        productService: widget.productService,
                        saleService: widget.saleService,
                        stockService: widget.stockService,
                        locationService: widget.locationService,
                        settingsController: widget.settingsController,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  _inventoryCountMode
                      ? Icons.inventory_rounded
                      : Icons.inventory_outlined,
                ),
                color: _inventoryCountMode
                    ? Theme.of(context).colorScheme.primary
                    : null,
                tooltip: 'Inventory count mode',
                onPressed: _toggleInventoryCountMode,
              ),
              IconButton(
                icon: Icon(
                  _inventoryCountMode
                      ? Icons.qr_code_2
                      : Icons.qr_code_scanner,
                ),
                tooltip: _inventoryCountMode
                    ? 'Scan items to count'
                    : 'Scan to find product',
                onPressed:
                _inventoryCountMode ? _scanToCount : _scanToFind,
              ),
              PopupMenuButton(
                icon: const Icon(Icons.filter_alt_outlined),
                onSelected: (filter) =>
                    setState(() => _filter = filter as ProductFilter),
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
              PopupMenuButton(
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
                  if (_inventoryCountMode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Inventory count mode is ON.\n'
                                  'Each scan will increment product quantity by 1.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_inventoryCountMode) const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name, SKU or barcode',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder(
                    valueListenable: productsBox.listenable(),
                    builder:
                        (context, Box<Product> box, _) {
                      final categories =
                      widget.productService.categories();
                      final hasUncategorized =
                      widget.productService.hasUncategorized();
                      final products =
                      widget.productService.getProducts(
                        searchQuery: _query,
                        filter: _filter,
                        category: _selectedCategory,
                      );

                      return Expanded(
                        child: Column(
                          children: [
                            if (categories.isNotEmpty || hasUncategorized)
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      FilterChip(
                                        selected:
                                        _selectedCategory == null,
                                        label: const Text('All categories'),
                                        onSelected: (_) => setState(
                                              () =>
                                          _selectedCategory = null,
                                        ),
                                      ),
                                      if (hasUncategorized)
                                        FilterChip(
                                          selected:
                                          _selectedCategory ==
                                              '__uncategorized__',
                                          label: const Text(
                                              'Uncategorized'),
                                          onSelected: (_) => setState(
                                                () => _selectedCategory =
                                            '__uncategorized__',
                                          ),
                                        ),
                                      ...categories.map(
                                            (category) => FilterChip(
                                          selected:
                                          _selectedCategory ==
                                              category,
                                          label: Text(category),
                                          onSelected: (_) => setState(
                                                () => _selectedCategory =
                                                category,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            Expanded(
                              child: products.isEmpty
                                  ? const Center(
                                child: Text(
                                  'No products yet.\nTap + to add one.',
                                  textAlign: TextAlign.center,
                                ),
                              )
                                  : ListView.builder(
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product =
                                  products[index];
                                  return ProductCard(
                                    product: product,
                                    highlightLowStock: widget
                                        .settingsController
                                        .highlightLowStock,
                                    onTap: () =>
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailPage(
                                                  productId: product.id,
                                                  productService:
                                                  widget
                                                      .productService,
                                                  settingsController:
                                                  widget
                                                      .settingsController,
                                                  stockService:
                                                      widget.stockService,
                                                  locationService:
                                                      widget.locationService,
                                                ),
                                          ),
                                        ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

  Future<void> _navigateToForm({
    Product? product,
    String? barcode,
  }) async {
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

  void _toggleInventoryCountMode() {
    setState(() => _inventoryCountMode = !_inventoryCountMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _inventoryCountMode
              ? 'Inventory count mode enabled.\nScans will add +1 to quantity.'
              : 'Inventory count mode disabled.',
        ),
      ),
    );
  }

  Future<void> _scanToFind() async {
    final code = await _openScanner();
    if (code == null) return;

    final product = widget.productService.findByBarcode(code);
    if (product != null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            productId: product.id,
            productService: widget.productService,
            settingsController: widget.settingsController,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Product not found'),
          content: Text(
            'Create a new product for barcode "$code"?',
          ),
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

  Future<void> _scanToCount() async {
    await _openScannerForCounting();
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

  Future<void> _openScannerForCounting() async {
    bool isHandling = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Inventory count mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('Scan items to add +1 to their recorded quantity.'),
                  ],
                ),
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) async {
                    final barcode = capture.barcodes.first.rawValue;
                    if (barcode == null || isHandling) return;
                    isHandling = true;
                    await _handleInventoryScan(barcode);
                    isHandling = false;
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: Text('Close when finished counting'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleInventoryScan(String code) async {
    final product = widget.productService.findByBarcode(code);
    if (product == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No product found for barcode "$code"')),
      );
      return;
    }

    final location = await widget.locationService
        .ensureLocationByName(widget.settingsController.activeLocation);
    try {
      await widget.stockService.adjustStock(
        productId: product.id,
        locationId: location.id,
        quantityChange: 1,
        type: 'count',
        note: 'Inventory count scan',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update stock: $error')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} counted. New qty: '
          '${widget.stockService.getQuantity(productId: product.id, locationId: location.id)}',
        ),
      ),
    );
  }

  Future<void> _exportStockReport() async {
    final products = widget.productService.getProducts();

    final rows = <List<String>>[
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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report saved to ${file.path}')),
    );
  }
}

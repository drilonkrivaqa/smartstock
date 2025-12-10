import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../services/hive_service.dart';
import '../services/location_service.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';
import '../services/settings_service.dart';
import '../services/stock_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.productService,
    required this.saleService,
    required this.stockService,
    required this.locationService,
    required this.settingsController,
  });

  final ProductService productService;
  final SaleService saleService;
  final StockService stockService;
  final LocationService locationService;
  final SettingsController settingsController;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Map<int, int> _cartItems = {};
  bool _processing = false;
  static const double _lowMarginThreshold = 10;

  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _customerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsBox = Hive.box<Product>(HiveService.productsBox);
    final locationName = widget.settingsController.activeLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout – $locationName'),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              onPressed: _processing
                  ? null
                  : () {
                setState(() {
                  _cartItems.clear();
                });
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _processing ? null : _scanAndAdd,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan product'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _openProductPicker,
                      icon: const Icon(Icons.search),
                      label: const Text('Add manually'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: productsBox.listenable(),
                  builder: (context, Box<Product> _, __) {
                    final items = _cartItems.entries
                        .map((entry) {
                      final product =
                      widget.productService.findById(entry.key);
                      if (product == null) return null;
                      return _CartEntry(
                        product: product,
                        quantity: entry.value,
                      );
                    })
                        .whereType<_CartEntry>()
                        .toList();

                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No items in the cart yet.\n'
                              'Scan or add products to start.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final maxAvailable = item.product.quantity;
                        final price = item.product.salePrice ?? 0;
                        final cost = item.product.purchasePrice ?? 0;
                        final lineTotal = price * item.quantity;
                        final lineCostTotal = cost * item.quantity;
                        final lineProfit = lineTotal - lineCostTotal;
                        final lineMarginPercent = lineTotal > 0
                            ? (lineProfit / lineTotal) * 100
                            : 0;
                        final isLowMargin =
                            lineMarginPercent < _lowMarginThreshold;

                        return Card(
                          child: ListTile(
                            title: Text(item.product.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('In stock: $maxAvailable'),
                                Text(
                                  'Price: ${price.toStringAsFixed(2)} | Line: ${lineTotal.toStringAsFixed(2)}',
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.stacked_line_chart,
                                      size: 16,
                                      color: isLowMargin
                                          ? Colors.orange
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Margin: ${lineMarginPercent.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: isLowMargin
                                            ? Colors.orange
                                            : null,
                                      ),
                                    ),
                                    if (isLowMargin) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Low margin',
                                          style: TextStyle(color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: _processing
                                          ? null
                                          : () => _changeQuantityBy(
                                                item.product.id,
                                                -1,
                                              ),
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                    ),
                                    Text(
                                      item.quantity.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    IconButton(
                                      onPressed: _processing
                                              ? null
                                              : () => _changeQuantityBy(
                                                    item.product.id,
                                                    1,
                                                  ),
                                      icon: const Icon(
                                          Icons.add_circle_outline),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    for (final inc in [1, 5, 10])
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          minimumSize: const Size(0, 32),
                                        ),
                                        onPressed: _processing
                                                ? null
                                                : () => _changeQuantityBy(
                                                      item.product.id,
                                                      inc,
                                                    ),
                                        child: Text('+${inc.toString()}'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerController,
                decoration: const InputDecoration(
                  labelText: 'Customer name (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Sale note (optional)',
                ),
                minLines: 1,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _CheckoutSummary(
                items: _cartItems,
                productService: widget.productService,
                saleService: widget.saleService,
                processing: _processing,
                onComplete: _completeSale,
                onAddProduct: _addProductToCart,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanAndAdd() async {
    final code = await _openScanner();
    if (code == null) return;

    final product = widget.productService.findByBarcode(code);
    if (product == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No product found for barcode "$code".'),
        ),
      );
      return;
    }

    _addProductToCart(product);
  }

  Future<void> _openProductPicker() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String query = '';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final products = widget.productService
                  .getProducts(searchQuery: query)
                  .where((p) => p.quantity > 0)
                  .toList();

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search products',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: products.isEmpty
                          ? const Center(
                        child: Text('No products found.'),
                      )
                          : ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              'In stock: ${product.quantity}',
                            ),
                            onTap: () =>
                                Navigator.of(context).pop(product),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (product != null) {
      _addProductToCart(product);
    }
  }

  void _addProductToCart(Product product) {
    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} is out of stock.')),
      );
      return;
    }

    final current = _cartItems[product.id] ?? 0;
    if (current >= product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${product.quantity} in stock.'),
        ),
      );
      return;
    }

    setState(() {
      _cartItems[product.id] = current + 1;
    });
  }

  void _changeQuantityBy(int productId, int delta) {
    final product = widget.productService.findById(productId);
    if (product == null) return;

    final current = _cartItems[productId] ?? 0;
    final newQuantity = current + delta;

    if (delta > 0 && newQuantity > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${product.quantity} in stock.'),
        ),
      );
      return;
    }

    if (newQuantity <= 0) {
      setState(() => _cartItems.remove(productId));
    } else {
      setState(() => _cartItems[productId] = newQuantity);
    }
  }

  Future<void> _completeSale() async {
    if (_cartItems.isEmpty || _processing) return;

    setState(() => _processing = true);

    final location = await widget.locationService
        .ensureLocationByName(widget.settingsController.activeLocation);

    for (final entry in _cartItems.entries) {
      final product = widget.productService.findById(entry.key);
      if (product == null) continue;
      final available = widget.stockService.getQuantity(
        productId: product.id,
        locationId: location.id,
      );
      if (entry.value > available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Not enough stock for ${product.name}. '
                    'Available: $available',
              ),
            ),
          );
        }
        setState(() => _processing = false);
        return;
      }
    }

    int totalItems = 0;
    double totalValue = 0;
    final saleItems = <SaleItem>[];

    for (final entry in _cartItems.entries) {
      final product = widget.productService.findById(entry.key);
      if (product == null) continue;

      final price = product.salePrice ?? 0;
      totalItems += entry.value;
      totalValue += price * entry.value;

      saleItems.add(
        SaleItem(
          productId: product.id,
          quantity: entry.value,
          unitPrice: price,
        ),
      );
    }

    final saleId = DateTime.now().microsecondsSinceEpoch;
    final locationName = widget.settingsController.activeLocation;

    final sale = Sale(
      id: saleId,
      date: DateTime.now(),
      totalItems: totalItems,
      totalValue: totalValue,
      items: saleItems,
      customerName: _customerController.text.trim().isEmpty
          ? null
          : _customerController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      locationName: locationName,
    );

    await widget.saleService.recordSale(sale, locationId: location.id);

    setState(() {
      _processing = false;
      _cartItems.clear();
      _customerController.clear();
      _noteController.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sale completed and stock updated.'),
      ),
    );
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
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({
    required this.items,
    required this.productService,
    required this.saleService,
    required this.processing,
    required this.onComplete,
    required this.onAddProduct,
  });

  final Map<int, int> items;
  final ProductService productService;
  final SaleService saleService;
  final bool processing;
  final VoidCallback onComplete;
  final ValueChanged<Product> onAddProduct;

  @override
  Widget build(BuildContext context) {
    int totalItems = 0;
    double basketSaleTotal = 0;
    double basketCostTotal = 0;

    items.forEach((id, quantity) {
      final product = productService.findById(id);
      if (product == null) return;

      final salePrice = product.salePrice ?? 0;
      final costPrice = product.purchasePrice ?? 0;

      totalItems += quantity;
      basketSaleTotal += salePrice * quantity;
      basketCostTotal += costPrice * quantity;
    });

    final basketProfit = basketSaleTotal - basketCostTotal;
    final basketMarginPercent = basketSaleTotal > 0
        ? (basketProfit / basketSaleTotal) * 100
        : 0;

    final suggestedProducts = _suggestedProducts();

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items: $totalItems'),
                const SizedBox(height: 4),
                Text(
                  'Total: ${basketSaleTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('Cost: ${basketCostTotal.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text('Profit: ${basketProfit.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text(
                  'Margin: ${basketMarginPercent.toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        items.isEmpty || processing ? null : onComplete,
                    icon: const Icon(Icons.point_of_sale),
                    label: processing
                        ? const Text('Processing...')
                        : const Text('Complete sale'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (suggestedProducts.isEmpty)
                  const Text('No suggestions right now.')
                else
                  ...suggestedProducts.map(
                    (product) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(product.name),
                      subtitle: Text(
                        'In stock: ${product.quantity}'
                        '${product.salePrice != null ? ' • ${product.salePrice!.toStringAsFixed(2)}' : ''}',
                      ),
                      trailing: OutlinedButton.icon(
                        onPressed: () => onAddProduct(product),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Product> _suggestedProducts() {
    final salesCounts =
        saleService.quantitySoldSince(DateTime.fromMillisecondsSinceEpoch(0));
    final products = productService
        .getProducts()
        .where((product) =>
            product.quantity > 0 && !items.keys.contains(product.id))
        .toList();

    products.sort((a, b) =>
        (salesCounts[b.id] ?? 0).compareTo(salesCounts[a.id] ?? 0));

    return products.take(3).toList();
  }
}

class _CartEntry {
  _CartEntry({required this.product, required this.quantity});

  final Product product;
  final int quantity;
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../services/hive_service.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.productService,
    required this.saleService,
  });

  final ProductService productService;
  final SaleService saleService;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Map<int, int> _cartItems = {};
  bool _processing = false;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              onPressed: _processing
                  ? null
                  : () => setState(() {
                        _cartItems.clear();
                      }),
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
                          return _CartEntry(product: product, quantity: entry.value);
                        })
                        .whereType<_CartEntry>()
                        .toList();

                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                            'No items in the cart yet. Scan or add products to start.'),
                      );
                    }

                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final maxAvailable = item.product.quantity;
                        final canIncrease = item.quantity < maxAvailable;
                        final price = item.product.salePrice;
                        final lineTotal =
                            price != null ? price * item.quantity : null;
                        return Card(
                          child: ListTile(
                            title: Text(item.product.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('In stock: $maxAvailable'),
                                if (price != null)
                                  Text(
                                    'Price: ${price.toStringAsFixed(2)}${lineTotal != null ? ' | Line: ${lineTotal.toStringAsFixed(2)}' : ''}',
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: _processing
                                      ? null
                                      : () => _decreaseQuantity(item.product.id),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  item.quantity.toString(),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  onPressed: _processing || !canIncrease
                                      ? null
                                      : () => _increaseQuantity(item.product.id),
                                  icon: const Icon(Icons.add_circle_outline),
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
                processing: _processing,
                onComplete: _completeSale,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No product found for barcode "$code".')),
        );
      }
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
                        onChanged: (value) => setSheetState(() {
                          query = value;
                        }),
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
                                  subtitle:
                                      Text('In stock: ${product.quantity}'),
                                  onTap: () => Navigator.of(context).pop(product),
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
    setState(() {
      _cartItems.update(product.id, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _increaseQuantity(int productId) {
    final product = widget.productService.findById(productId);
    if (product == null) return;
    final current = _cartItems[productId] ?? 0;
    if (current >= product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${product.quantity} in stock.')),
      );
      return;
    }
    setState(() => _cartItems[productId] = current + 1);
  }

  void _decreaseQuantity(int productId) {
    final current = _cartItems[productId];
    if (current == null) return;
    if (current <= 1) {
      setState(() => _cartItems.remove(productId));
    } else {
      setState(() => _cartItems[productId] = current - 1);
    }
  }

  Future<void> _completeSale() async {
    if (_cartItems.isEmpty || _processing) return;
    setState(() => _processing = true);

    for (final entry in _cartItems.entries) {
      final product = widget.productService.findById(entry.key);
      if (product == null) continue;
      if (entry.value > product.quantity) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Not enough stock for ${product.name}. Available: ${product.quantity}'),
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
    );

    await widget.saleService.recordSale(sale);

    for (final entry in _cartItems.entries) {
      final product = widget.productService.findById(entry.key);
      if (product == null) continue;
      await widget.productService.adjustStock(
        product: product,
        change: -entry.value,
        type: 'sale',
        note: 'Checkout sale',
        saleId: saleId,
      );
    }

    setState(() {
      _processing = false;
      _cartItems.clear();
      _customerController.clear();
      _noteController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale completed and stock updated.')),
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
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({
    required this.items,
    required this.productService,
    required this.processing,
    required this.onComplete,
  });

  final Map<int, int> items;
  final ProductService productService;
  final bool processing;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    int totalItems = 0;
    double totalValue = 0;

    items.forEach((id, quantity) {
      final product = productService.findById(id);
      if (product == null) return;
      totalItems += quantity;
      if (product.salePrice != null) {
        totalValue += product.salePrice! * quantity;
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items: $totalItems'),
            const SizedBox(height: 4),
            Text(
              'Total: ${totalValue.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: items.isEmpty || processing ? null : onComplete,
                icon: const Icon(Icons.point_of_sale),
                label: processing
                    ? const Text('Processing...')
                    : const Text('Complete sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartEntry {
  _CartEntry({required this.product, required this.quantity});

  final Product product;
  final int quantity;
}

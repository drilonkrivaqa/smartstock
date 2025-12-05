import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/product.dart';
import '../services/product_service.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    super.key,
    required this.productService,
    this.existing,
    this.prefilledBarcode,
  });

  final ProductService productService;
  final Product? existing;
  final String? prefilledBarcode;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _categoryController;
  late TextEditingController _locationController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _quantityController;
  late TextEditingController _minQuantityController;
  late TextEditingController _notesController;
  String? _barcode;
  DateTime? _expiryDate;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _skuController = TextEditingController(text: existing?.sku ?? '');
    _categoryController = TextEditingController(text: existing?.category ?? '');
    _locationController =
        TextEditingController(text: existing?.location ?? '');
    _purchasePriceController = TextEditingController(
      text: existing?.purchasePrice?.toString() ?? '',
    );
    _salePriceController =
        TextEditingController(text: existing?.salePrice?.toString() ?? '');
    _quantityController =
        TextEditingController(text: existing?.quantity.toString() ?? '0');
    _minQuantityController =
        TextEditingController(text: existing?.minQuantity.toString() ?? '0');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _barcode = widget.prefilledBarcode ?? existing?.barcode;
    _expiryDate = existing?.expiryDate;
    _photoPath = existing?.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit product' : 'Add product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceController,
                        decoration:
                            const InputDecoration(labelText: 'Purchase price'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _salePriceController,
                        decoration: const InputDecoration(labelText: 'Sale price'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null) {
                            return 'Enter quantity';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minQuantityController,
                        decoration:
                            const InputDecoration(labelText: 'Minimum quantity'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null) {
                            return 'Enter min quantity';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _photoPath == null
                          ? const Text('No photo selected')
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_photoPath!),
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_camera_back_outlined),
                      label: const Text('Add photo'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickExpiryDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry date (optional)',
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _expiryDate != null
                                ? _formatDate(_expiryDate!)
                                : 'Not set',
                          ),
                        ),
                        if (_expiryDate != null)
                          IconButton(
                            onPressed: () => setState(() => _expiryDate = null),
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear expiry date',
                          ),
                        const Icon(Icons.calendar_month),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_barcode != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: const Icon(Icons.qr_code),
                      label: Text(_barcode!),
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _openScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan barcode / QR'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Update product' : 'Save product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openScanner() async {
    final code = await showModalBottomSheet<String>(
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
    if (code != null) {
      setState(() => _barcode = code);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _photoPath = file.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final product = Product(
      id: widget.existing?.id ?? now.microsecondsSinceEpoch,
      name: _nameController.text.trim(),
      sku: _skuController.text.trim().isEmpty
          ? null
          : _skuController.text.trim(),
      barcode: _barcode,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      purchasePrice: _purchasePriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_purchasePriceController.text.trim()),
      salePrice: _salePriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_salePriceController.text.trim()),
      quantity: int.parse(_quantityController.text.trim()),
      minQuantity: int.parse(_minQuantityController.text.trim()),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      expiryDate: _expiryDate,
      photoPath: _photoPath,
    );
    await widget.productService.addOrUpdateProduct(product);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.existing != null ? 'Product updated' : 'Product saved'),
        ),
      );
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: _expiryDate ?? now,
    );
    if (selected != null) {
      setState(() => _expiryDate = selected);
    }
  }

  String _formatDate(DateTime date) {
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
  }
}

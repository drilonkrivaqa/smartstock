import 'package:flutter/material.dart';

import '../models/product.dart';

class StockAdjustmentResult {
  StockAdjustmentResult({
    required this.change,
    required this.type,
    this.note,
  });

  final double change;
  final String type;
  final String? note;
}

class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({super.key, required this.product});

  final Product product;

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  String _type = 'restock';

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adjust stock for ${widget.product.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration:
                      const InputDecoration(labelText: 'Quantity change'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed == 0) {
                      return 'Enter a non-zero number';
                    }
                    if (_type == 'sale' && parsed > 0) {
                      return 'Sales should be negative';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'restock', child: Text('Restock')),
                    DropdownMenuItem(value: 'sale', child: Text('Sale')),
                    DropdownMenuItem(
                        value: 'correction', child: Text('Correction')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    double change = double.parse(_quantityController.text.trim());
    if (_type == 'restock' && change < 0) {
      change = change.abs();
    }
    if (_type == 'sale' && change > 0) {
      change = -change;
    }
    final result = StockAdjustmentResult(
      change: change,
      type: _type,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    Navigator.of(context).pop(result);
  }
}

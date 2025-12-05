import 'package:flutter/material.dart';

import '../services/product_service.dart';
import '../services/sale_service.dart';
import '../services/settings_service.dart';
import 'home_page.dart';
import 'reports_page.dart';
import 'sales_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.productService,
    required this.settingsController,
    required this.saleService,
  });

  final ProductService productService;
  final SettingsController settingsController;
  final SaleService saleService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), label: 'Products'),
      NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), label: 'Sales'),
      NavigationDestination(icon: const Icon(Icons.analytics_outlined), label: 'Reports'),
      NavigationDestination(icon: const Icon(Icons.settings_outlined), label: 'Settings'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(
            productService: widget.productService,
            settingsController: widget.settingsController,
          ),
          SalesPage(
            saleService: widget.saleService,
            productService: widget.productService,
          ),
          ReportsPage(
            productService: widget.productService,
            saleService: widget.saleService,
          ),
          SettingsPage(settingsController: widget.settingsController),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: destinations,
      ),
    );
  }
}

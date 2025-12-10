import 'package:flutter/material.dart';

import '../services/product_service.dart';
import '../services/sale_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../services/stock_service.dart';
import 'home_page.dart';
import 'reports_page.dart';
import 'sales_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.locationService,
    required this.stockService,
    required this.productService,
    required this.saleService,
    required this.settingsController,
  });

  final LocationService locationService;
  final StockService stockService;
  final ProductService productService;
  final SaleService saleService;
  final SettingsController settingsController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProductsPage(
        productService: widget.productService,
        stockService: widget.stockService,
        locationService: widget.locationService,
        settingsController: widget.settingsController,
        saleService: widget.saleService,
      ),
      SalesPage(
        saleService: widget.saleService,
      ),
      ReportsPage(
        productService: widget.productService,
        saleService: widget.saleService,
      ),
      SettingsPage(settingsController: widget.settingsController),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'pages/main_shell.dart';
import 'services/hive_service.dart';
import 'services/location_service.dart';
import 'services/product_service.dart';
import 'services/sale_service.dart';
import 'services/settings_service.dart';
import 'services/stock_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  final locationService = await buildLocationService();
  final settingsController = await buildSettingsController();
  final productService = await buildProductService();
  final stockService = await buildStockService(locationService);
  final saleService = await buildSaleService(stockService);
  runApp(
    SmartStockApp(
      stockService: stockService,
      locationService: locationService,
      settingsController: settingsController,
      productService: productService,
      saleService: saleService,
    ),
  );
}

class SmartStockApp extends StatelessWidget {
  const SmartStockApp({
    super.key,
    required this.settingsController,
    required this.productService,
    required this.saleService,
    required this.locationService,
    required this.stockService,
  });

  final SettingsController settingsController;
  final ProductService productService;
  final SaleService saleService;
  final LocationService locationService;
  final StockService stockService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SmartStock',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode:
              settingsController.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: MainShell(
            locationService: locationService,
            stockService: stockService,
            productService: productService,
            saleService: saleService,
            settingsController: settingsController,
          ),
        );
      },
    );
  }
}

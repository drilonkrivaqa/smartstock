import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/main_shell.dart';
import 'services/hive_service.dart';
import 'services/product_service.dart';
import 'services/sale_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  final settingsController = await buildSettingsController();
  final productService = await buildProductService();
  final saleService = await buildSaleService(productService);
  runApp(
    SmartStockApp(
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
  });

  final SettingsController settingsController;
  final ProductService productService;
  final SaleService saleService;

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
            productService: productService,
            settingsController: settingsController,
            saleService: saleService,
          ),
        );
      },
    );
  }
}

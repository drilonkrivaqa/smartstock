import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'services/hive_service.dart';
import 'services/product_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  final settingsController = await buildSettingsController();
  final productService = await buildProductService();
  runApp(
    SmartStockApp(
      settingsController: settingsController,
      productService: productService,
    ),
  );
}

class SmartStockApp extends StatelessWidget {
  const SmartStockApp({
    super.key,
    required this.settingsController,
    required this.productService,
  });

  final SettingsController settingsController;
  final ProductService productService;

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
          home: HomePage(
            productService: productService,
            settingsController: settingsController,
          ),
        );
      },
    );
  }
}

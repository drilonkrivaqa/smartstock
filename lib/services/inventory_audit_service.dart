import 'package:hive/hive.dart';

import '../models/audit.dart';
import '../models/product.dart';
import '../services/hive_service.dart';
import 'stock_service.dart';

class InventoryAuditService {
  InventoryAuditService({
    required this.auditSessionsBox,
    required this.productsBox,
    required this.stockService,
  });

  final Box<AuditSession> auditSessionsBox;
  final Box<Product> productsBox;
  final StockService stockService;

  Future<AuditSession> startSession({required int locationId}) async {
    final session = AuditSession(
      id: DateTime.now().microsecondsSinceEpoch,
      locationId: locationId,
      startedAt: DateTime.now(),
      status: 'in_progress',
    );
    await auditSessionsBox.add(session);
    return session;
  }

  AuditSession? getSession(int id) {
    try {
      return auditSessionsBox.values.firstWhere((session) => session.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<AuditSession> recordCount({
    required int sessionId,
    required int productId,
    required double countedQuantity,
  }) async {
    final session = getSession(sessionId);
    if (session == null) {
      throw Exception('Audit session not found');
    }

    final expected = stockService.getQuantity(
      productId: productId,
      locationId: session.locationId,
    );
    final product = productsBox.values.firstWhere(
      (p) => p.id == productId,
      orElse: () => Product(
        id: productId,
        name: 'Unknown',
        quantity: 0,
        minQuantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final unitCost = product.purchasePrice ?? 0;
    final newLine = AuditLine(
      productId: productId,
      countedQuantity: countedQuantity,
      expectedQuantity: expected,
      unitCost: unitCost,
    );

    final updatedLines = [...session.lines];
    final index = updatedLines.indexWhere((line) => line.productId == productId);
    if (index >= 0) {
      updatedLines[index] = newLine;
    } else {
      updatedLines.add(newLine);
    }

    session
      ..lines = updatedLines
      ..save();
    return session;
  }

  Future<AuditSession> finalizeSession(int sessionId) async {
    final session = getSession(sessionId);
    if (session == null) {
      throw Exception('Audit session not found');
    }
    if (session.status == 'completed') return session;

    for (final line in session.lines.where((line) => line.difference != 0)) {
      await stockService.adjustStock(
        productId: line.productId,
        locationId: session.locationId,
        quantityChange: line.difference,
        type: 'adjustment',
        reasonCode: 'audit_discrepancy',
        note: 'Audit ${session.id}',
        unitCost: line.unitCost,
      );
    }

    session
      ..status = 'completed'
      ..finishedAt = DateTime.now();
    await session.save();
    return session;
  }

  List<AuditLine> topDiscrepancies(AuditSession session, {int limit = 5}) {
    final sorted = [...session.lines]
      ..sort((a, b) => b.differenceValue.compareTo(a.differenceValue));
    return sorted.take(limit).toList();
  }
}

Future<InventoryAuditService> buildInventoryAuditService(
  StockService stockService,
) async {
  final auditSessions = Hive.box<AuditSession>(HiveService.auditSessionsBox);
  final products = Hive.box<Product>(HiveService.productsBox);
  return InventoryAuditService(
    auditSessionsBox: auditSessions,
    productsBox: products,
    stockService: stockService,
  );
}

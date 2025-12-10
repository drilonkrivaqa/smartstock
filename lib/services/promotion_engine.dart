import '../models/price_rule.dart';

class CartItem {
  CartItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.category,
    this.name,
  });

  final int productId;
  final int quantity;
  final double unitPrice;
  final String? category;
  final String? name;
}

class CartContext {
  CartContext({
    required this.items,
    required this.locationId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final List<CartItem> items;
  final int locationId;
  final DateTime timestamp;
}

class AppliedPromotion {
  AppliedPromotion({
    required this.rule,
    required this.discount,
    this.freeItems = const <CartItem>[],
  });

  final PriceRule rule;
  final double discount;
  final List<CartItem> freeItems;
}

class PromotionResult {
  PromotionResult({
    required this.appliedPromotions,
  });

  final List<AppliedPromotion> appliedPromotions;

  double get totalDiscount =>
      appliedPromotions.fold(0, (value, p) => value + p.discount);

  List<CartItem> get freeItems =>
      appliedPromotions.expand((p) => p.freeItems).toList();
}

class PromotionEngine {
  List<AppliedPromotion> applyRules(
    List<PriceRule> rules,
    CartContext context,
  ) {
    final now = context.timestamp;
    final sortedRules = [...rules]
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final applied = <AppliedPromotion>[];
    for (final rule in sortedRules.where((rule) => rule.isActive(now, locationId: context.locationId))) {
      final matchingItems = _filterItems(context.items, rule);
      if (matchingItems.isEmpty) continue;

      switch (rule.effectType) {
        case 'percentageDiscount':
          final discount = _percentageDiscount(rule, matchingItems);
          if (discount > 0) {
            applied.add(AppliedPromotion(rule: rule, discount: discount));
          }
          break;
        case 'fixedPrice':
          final discount = _fixedPriceDiscount(rule, matchingItems);
          if (discount > 0) {
            applied.add(AppliedPromotion(rule: rule, discount: discount));
          }
          break;
        case 'freeItem':
          final promo = _freeItem(rule, matchingItems);
          if (promo != null) {
            applied.add(promo);
          }
          break;
        default:
          break;
      }
    }

    return applied;
  }

  List<CartItem> _filterItems(List<CartItem> items, PriceRule rule) {
    switch (rule.targetType) {
      case 'product':
        return items
            .where((item) => rule.targetIds.contains(item.productId.toString()))
            .toList();
      case 'category':
        return items
            .where((item) => item.category != null && rule.targetIds.contains(item.category))
            .toList();
      case 'all':
      default:
        return items;
    }
  }

  double _percentageDiscount(PriceRule rule, List<CartItem> items) {
    final percent = rule.effectValue ?? 0;
    if (percent <= 0) return 0;
    final minimum = rule.conditionMinQty ?? 0;
    final totalQty = items.fold<int>(0, (value, item) => value + item.quantity);
    if (totalQty < minimum) return 0;
    final totalValue =
        items.fold<double>(0, (value, item) => value + item.unitPrice * item.quantity);
    return totalValue * (percent / 100);
  }

  double _fixedPriceDiscount(PriceRule rule, List<CartItem> items) {
    final fixedPrice = rule.effectValue ?? 0;
    if (fixedPrice <= 0) return 0;
    double discount = 0;
    for (final item in items) {
      if (rule.conditionMinQty != null && item.quantity < rule.conditionMinQty!) {
        continue;
      }
      if (item.unitPrice > fixedPrice) {
        discount += (item.unitPrice - fixedPrice) * item.quantity;
      }
    }
    return discount;
  }

  AppliedPromotion? _freeItem(PriceRule rule, List<CartItem> items) {
    final requiredQty = rule.conditionMinQty ?? 0;
    final rewardQty = rule.rewardQuantity ?? 0;
    if (requiredQty <= 0 || rewardQty <= 0) return null;

    int totalBundles = 0;
    for (final item in items) {
      totalBundles += item.quantity ~/ (requiredQty + rewardQty);
    }
    if (totalBundles <= 0) return null;

    final freeItemProductId = rule.rewardProductId ?? items.first.productId;
    final totalFreeUnits = totalBundles * rewardQty;
    final freeItem = CartItem(
      productId: freeItemProductId,
      quantity: totalFreeUnits,
      unitPrice: 0,
      category: items.first.category,
      name: items.first.name,
    );
    final discount = items.first.unitPrice * totalFreeUnits;
    return AppliedPromotion(rule: rule, discount: discount, freeItems: [freeItem]);
  }
}

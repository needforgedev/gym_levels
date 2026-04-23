import '../schema.dart';

class Subscription {
  const Subscription({
    this.userId = 1,
    this.tier = 'free',
    this.status = 'inactive',
    this.purchasedAt,
    this.renewsAt,
    this.receiptData,
    this.lastVerifiedAt,
    required this.updatedAt,
  });

  final int userId;
  final String tier;
  final String status;
  final int? purchasedAt;
  final int? renewsAt;
  final String? receiptData;
  final int? lastVerifiedAt;
  final int updatedAt;

  bool get isPro {
    if (tier == 'free' || status != 'active') return false;
    if (renewsAt == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return renewsAt! > now;
  }

  factory Subscription.fromRow(Map<String, Object?> r) => Subscription(
        userId: r[CSubscription.userId] as int,
        tier: r[CSubscription.tier] as String? ?? 'free',
        status: r[CSubscription.status] as String? ?? 'inactive',
        purchasedAt: r[CSubscription.purchasedAt] as int?,
        renewsAt: r[CSubscription.renewsAt] as int?,
        receiptData: r[CSubscription.receiptData] as String?,
        lastVerifiedAt: r[CSubscription.lastVerifiedAt] as int?,
        updatedAt: r[CSubscription.updatedAt] as int,
      );

  Map<String, Object?> toRow() => {
        CSubscription.userId: userId,
        CSubscription.tier: tier,
        CSubscription.status: status,
        CSubscription.purchasedAt: purchasedAt,
        CSubscription.renewsAt: renewsAt,
        CSubscription.receiptData: receiptData,
        CSubscription.lastVerifiedAt: lastVerifiedAt,
        CSubscription.updatedAt: updatedAt,
      };
}

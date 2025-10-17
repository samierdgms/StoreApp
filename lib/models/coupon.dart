class Coupon {
  final String code;
  final String type;
  final double value;
  final double minAmount;
  final String description;
  final bool isActive;

  Coupon({
    required this.code,
    required this.type,
    required this.value,
    required this.minAmount,
    required this.description,
    required this.isActive,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code'],
      type: json['type'],
      value: (json['value'] as num).toDouble(),
      minAmount: (json['min_amount'] as num).toDouble(),
      description: json['description'],
      isActive: json['is_active'] ?? false,
    );
  }
}

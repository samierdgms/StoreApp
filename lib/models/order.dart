class Order {
  final String? id;
  final String userId;
  final List<dynamic> products;
  final double totalPrice;
  final String? couponCode;
  final double? discountAmount;
  final double finalPrice;
  final double deliveryFee;
  final String paymentMethod;
  final String status;
  final String deliveryAddress;
  final DateTime createdAt;
  final String? orderNote;

  Order({
    this.id,
    required this.userId,
    required this.products,
    required this.totalPrice,
    this.couponCode,
    this.discountAmount,
    required this.finalPrice,
    required this.deliveryFee,
    required this.paymentMethod,
    required this.status,
    required this.deliveryAddress,
    required this.createdAt,
    this.orderNote,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      userId: map['user_id'],
      products: map['products'],
      totalPrice: (map['total_price'] as num).toDouble(),
      couponCode: map['coupon_code'],
      discountAmount: map['discount_amount'] != null
          ? (map['discount_amount'] as num).toDouble()
          : null,
      finalPrice: (map['final_price'] as num).toDouble(),
      deliveryFee: map['delivery_fee'] != null
          ? (map['delivery_fee'] as num).toDouble()
          : 0.0, // ✅ varsayılan 0.0
      paymentMethod: map['payment_method'],
      status: map['status'],
      deliveryAddress: map['delivery_address'],
      createdAt: DateTime.parse(map['created_at']),
      orderNote: map['order_note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'products': products,
      'total_price': totalPrice,
      'coupon_code': couponCode,
      'discount_amount': discountAmount,
      'final_price': finalPrice,
      'delivery_fee': deliveryFee, // ✅ eklendi
      'payment_method': paymentMethod,
      'status': status,
      'delivery_address': deliveryAddress,
      'order_note':orderNote,
      'created_at': createdAt.toIso8601String(),

    };
  }
}

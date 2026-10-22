class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        menuItemId: m['menuItemId'] ?? '',
        name: m['name'] ?? '',
        price: (m['price'] ?? 0.0).toDouble(),
        quantity: m['quantity'] ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'menuItemId': menuItemId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}

enum OrderStatus { pending, confirmed, ready, cancelled }
enum DonationStatus { pending, paid, confirmed, disputed }

class Order {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String causeId;
  final String causeName;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? notes;
  final String? deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double donationAmount;
  final double deliveryFee;
  final OrderStatus status;
  final DonationStatus donationStatus;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.causeId,
    required this.causeName,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.notes,
    this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.donationAmount,
    this.deliveryFee = 0.0,
    required this.status,
    required this.donationStatus,
    required this.createdAt,
  });

  factory Order.fromMap(String id, Map<String, dynamic> m) => Order(
        id: id,
        restaurantId: m['restaurantId'] ?? '',
        restaurantName: m['restaurantName'] ?? '',
        causeId: m['causeId'] ?? '',
        causeName: m['causeName'] ?? '',
        customerName: m['customerName'] ?? '',
        customerEmail:   m['customerEmail'],
        customerPhone:   m['customerPhone'],
        notes:           m['notes'],
        deliveryAddress: m['deliveryAddress'],
        items: (m['items'] as List<dynamic>? ?? [])
            .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
            .toList(),
        subtotal: (m['subtotal'] ?? 0.0).toDouble(),
        donationAmount: (m['donationAmount'] ?? 0.0).toDouble(),
        deliveryFee: (m['deliveryFee'] ?? 0.0).toDouble(),
        status: OrderStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => OrderStatus.pending,
        ),
        donationStatus: DonationStatus.values.firstWhere(
          (s) => s.name == m['donationStatus'],
          orElse: () => DonationStatus.pending,
        ),
        createdAt: m['createdAt'] != null
            ? (m['createdAt'] as dynamic).toDate()
            : DateTime.now(),
      );
}

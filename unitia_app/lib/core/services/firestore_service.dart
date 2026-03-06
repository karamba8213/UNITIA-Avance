import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/restaurant.dart';
import '../models/cause.dart';
import '../models/order.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── RESTAURANT ───────────────────────────────────────────

  Stream<Restaurant?> restaurantStream(String uid) => _db
      .collection('restaurants')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? Restaurant.fromMap(s.id, s.data()!) : null);

  Future<Restaurant?> getRestaurant(String uid) async {
    final s = await _db.collection('restaurants').doc(uid).get();
    return s.exists ? Restaurant.fromMap(s.id, s.data()!) : null;
  }

  Future<void> updateRestaurant(String uid, Map<String, dynamic> data) =>
      _db.collection('restaurants').doc(uid).update(data);

  Stream<List<Map<String, dynamic>>> menuItemsStream(String restaurantId) =>
      _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .where('isAvailable', isEqualTo: true)
          .orderBy('category')
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> addMenuItem(String restaurantId, Map<String, dynamic> data) =>
      _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .add({...data, 'isAvailable': true, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateMenuItem(String restaurantId, String itemId, Map<String, dynamic> data) =>
      _db.collection('restaurants').doc(restaurantId).collection('menu').doc(itemId).update(data);

  Future<void> deleteMenuItem(String restaurantId, String itemId) =>
      _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .doc(itemId)
          .update({'isAvailable': false});

  // ─── CAUSE ────────────────────────────────────────────────

  Stream<Cause?> causeStream(String uid) => _db
      .collection('causes')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? Cause.fromMap(s.id, s.data()!) : null);

  Future<void> updateCause(String uid, Map<String, dynamic> data) =>
      _db.collection('causes').doc(uid).update(data);

  Future<List<Cause>> getActiveCauses() async {
    final snap = await _db
        .collection('causes')
        .where('isVerified', isEqualTo: true)
        .orderBy('name')
        .get();
    return snap.docs.map((d) => Cause.fromMap(d.id, d.data())).toList();
  }

  Future<Cause?> getCause(String uid) async {
    final s = await _db.collection('causes').doc(uid).get();
    return s.exists ? Cause.fromMap(s.id, s.data()!) : null;
  }

  Future<Cause?> getCauseBySlug(String slug) async {
    final snap = await _db
        .collection('causes')
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Cause.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  // ─── ORDERS ───────────────────────────────────────────────

  /// Creates an order + donation atomically
  Future<String> createOrder({
    required String restaurantId,
    required String restaurantName,
    required String causeId,
    required String causeName,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
    String? causeMessage,
    String? deliveryAddress,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double donationAmount,
  }) async {
    final batch = _db.batch();

    final orderRef = _db.collection('orders').doc();
    batch.set(orderRef, {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'causeId': causeId,
      'causeName': causeName,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'notes': notes,
      if (causeMessage != null) 'causeMessage': causeMessage,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      'items': items,
      'subtotal': subtotal,
      'donationAmount': donationAmount,
      'status': 'pending',
      'donationStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Donation document
    final donationRef = _db.collection('donations').doc(orderRef.id);
    batch.set(donationRef, {
      'orderId': orderRef.id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'causeId': causeId,
      'causeName': causeName,
      'customerName': customerName,
      'amount': donationAmount,
      'status': 'pending',
      if (causeMessage != null) 'causeMessage': causeMessage,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return orderRef.id;
  }

  Future<void> updateOrderStatus(String orderId, String status) =>
      _db.collection('orders').doc(orderId).update({'status': status});

  Stream<List<Order>> restaurantOrdersStream(String restaurantId) => _db
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => Order.fromMap(d.id, d.data())).toList());

  Stream<List<Map<String, dynamic>>> restaurantOrdersRawStream(String restaurantId) => _db
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> restaurantDonationsStream(
          String restaurantId, String? statusFilter) =>
      _db
          .collection('donations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: statusFilter ?? 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> causeDonationsStream(
          String causeId, String statusFilter) =>
      _db
          .collection('donations')
          .where('causeId', isEqualTo: causeId)
          .where('status', isEqualTo: statusFilter)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> markDonationPaid(String donationId, String orderId, {String? notes}) async {
    final batch = _db.batch();
    batch.update(_db.collection('donations').doc(donationId), {
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      if (notes != null) 'notes': notes,
    });
    batch.update(_db.collection('orders').doc(orderId), {'donationStatus': 'paid'});
    await batch.commit();
  }

  Future<void> confirmDonationReceived(String donationId, String orderId, String causeId) async {
    final batch = _db.batch();
    batch.update(_db.collection('donations').doc(donationId), {
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('orders').doc(orderId), {'donationStatus': 'confirmed'});
    // Update cause totalRaised
    final donation = await _db.collection('donations').doc(donationId).get();
    final amount = (donation.data()?['amount'] ?? 0.0).toDouble();
    batch.update(_db.collection('causes').doc(causeId), {
      'totalRaised': FieldValue.increment(amount),
    });
    await batch.commit();
  }

  // ─── DASHBOARD STATS ──────────────────────────────────────

  Future<Map<String, dynamic>> getRestaurantDashboard(String restaurantId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final allDonations = await _db
        .collection('donations')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    double totalPending = 0, totalPaid = 0, totalConfirmed = 0;
    int countPending = 0;

    for (final doc in allDonations.docs) {
      final amount = (doc['amount'] ?? 0.0).toDouble();
      final status = doc['status'];
      if (status == 'pending') { totalPending += amount; countPending++; }
      if (status == 'paid') totalPaid += amount;
      if (status == 'confirmed') totalConfirmed += amount;
    }

    final todayOrders = await _db
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .get();

    double todayRevenue = 0, todayDonations = 0;
    for (final doc in todayOrders.docs) {
      todayRevenue += (doc['subtotal'] ?? 0.0).toDouble();
      todayDonations += (doc['donationAmount'] ?? 0.0).toDouble();
    }

    return {
      'todayOrders': todayOrders.size,
      'todayRevenue': todayRevenue,
      'todayDonations': todayDonations,
      'totalPending': totalPending,
      'totalPaid': totalPaid,
      'totalConfirmed': totalConfirmed,
      'countPending': countPending,
    };
  }

  Future<Map<String, dynamic>> getCauseDashboard(String causeId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final allDonations = await _db
        .collection('donations')
        .where('causeId', isEqualTo: causeId)
        .get();

    double totalRaised = 0, pendingAmount = 0;
    double todayDonations = 0;
    final Set<String> restaurants = {};

    for (final doc in allDonations.docs) {
      final amount = (doc['amount'] ?? 0.0).toDouble();
      final status = doc['status'];
      if (status == 'confirmed') totalRaised += amount;
      if (status == 'pending' || status == 'paid') pendingAmount += amount;
      if (doc['restaurantId'] != null) restaurants.add(doc['restaurantId'] as String);
      final createdAt = doc['createdAt'];
      if (createdAt is Timestamp && createdAt.toDate().isAfter(todayStart)) {
        todayDonations += amount;
      }
    }

    return {
      'todayDonations': todayDonations,
      'totalRaised': totalRaised,
      'pendingAmount': pendingAmount,
      'restaurantCount': restaurants.length,
    };
  }

  // ─── CUSTOMER PROFILE ─────────────────────────────────────

  Future<Map<String, dynamic>?> getCustomerProfile(String uid) async {
    final s = await _db.collection('customers').doc(uid).get();
    return s.exists ? s.data() : null;
  }

  Future<void> updateCustomerProfile(String uid, Map<String, dynamic> data) =>
      _db.collection('customers').doc(uid).set(data, SetOptions(merge: true));

  // ─── CUSTOMER BROWSE ──────────────────────────────────────

  Future<List<Restaurant>> getActiveRestaurants() async {
    final snap = await _db
        .collection('restaurants')
        .where('isVerified', isEqualTo: true)
        .orderBy('name')
        .get();
    return snap.docs.map((d) => Restaurant.fromMap(d.id, d.data())).toList();
  }

  Future<List<Map<String, dynamic>>> getMenuItems(String restaurantId) async {
    final snap = await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .where('isAvailable', isEqualTo: true)
        .orderBy('category')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Stream<Order?> orderStream(String orderId) => _db
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((s) => s.exists ? Order.fromMap(s.id, s.data()!) : null);

  // ─── CUSTOMER IMPACT ──────────────────────────────────────

  Future<Map<String, dynamic>> getCustomerImpact(String email) async {
    final orders = await _db
        .collection('orders')
        .where('customerEmail', isEqualTo: email)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('createdAt', descending: true)
        .get();

    if (orders.docs.isEmpty) {
      return {'totalDonated': 0.0, 'totalOrders': 0, 'byCause': [], 'recentOrders': []};
    }

    double totalDonated = 0;
    final Map<String, Map<String, dynamic>> byCauseMap = {};

    for (final doc in orders.docs) {
      final amount = (doc['donationAmount'] ?? 0.0).toDouble();
      totalDonated += amount;
      final causeId = doc['causeId'] as String;
      if (!byCauseMap.containsKey(causeId)) {
        byCauseMap[causeId] = {
          'causeId': causeId,
          'causeName': doc['causeName'],
          'totalDonated': 0.0,
          'count': 0,
        };
      }
      byCauseMap[causeId]!['totalDonated'] += amount;
      byCauseMap[causeId]!['count'] += 1;
    }

    final byCause = byCauseMap.values.toList()
      ..sort((a, b) => (b['totalDonated'] as double).compareTo(a['totalDonated'] as double));

    return {
      'totalDonated': totalDonated,
      'totalOrders': orders.size,
      'byCause': byCause,
      'recentOrders': orders.docs.take(10).map((d) => {'id': d.id, ...d.data()}).toList(),
    };
  }
}

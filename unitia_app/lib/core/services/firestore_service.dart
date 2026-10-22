import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/restaurant.dart';
import '../models/cause.dart';
import '../models/cause_update.dart';
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
          .snapshots()
          .map((s) {
            final items = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
            items.sort((a, b) => (a['category'] as String? ?? '').compareTo(b['category'] as String? ?? ''));
            return items;
          });

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

  Future<List<String>> getMenuCategories(String restaurantId) async {
    final s = await _db.collection('restaurants').doc(restaurantId).get();
    final saved = List<String>.from(s.data()?['menuCategories'] ?? []);
    return saved;
  }

  Future<void> saveMenuCategories(String restaurantId, List<String> categories) =>
      _db.collection('restaurants').doc(restaurantId).update({'menuCategories': categories});

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

  /// Creates an order + donation atomically and increments cause helpers
  Future<String> createOrder({
    required String restaurantId,
    required String restaurantName,
    required String causeId,
    required String causeName,
    required String customerName,
    String? customerId,
    String? customerEmail,
    String? customerPhone,
    String? notes,
    String? causeMessage,
    String? deliveryAddress,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double donationAmount,
    double deliveryFee = 0.0,
  }) async {
    final batch = _db.batch();

    final orderRef = _db.collection('orders').doc();
    batch.set(orderRef, {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'causeId': causeId,
      'causeName': causeName,
      'customerName': customerName,
      if (customerId != null) 'customerId': customerId,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'notes': notes,
      if (causeMessage != null) 'causeMessage': causeMessage,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      'items': items,
      'subtotal': subtotal,
      'donationAmount': donationAmount,
      'deliveryFee': deliveryFee,
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
      if (customerId != null) 'customerId': customerId,
      'amount': donationAmount,
      'status': 'pending',
      if (causeMessage != null) 'causeMessage': causeMessage,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment helpers count on the cause
    batch.update(_db.collection('causes').doc(causeId), {
      'helpersCount': FieldValue.increment(1),
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

  Future<void> markDonationPaid(String donationId, String orderId,
      {String? notes, String? paymentMethod}) async {
    final batch = _db.batch();
    batch.update(_db.collection('donations').doc(donationId), {
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      if (notes != null) 'notes': notes,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    });
    batch.update(_db.collection('orders').doc(orderId), {'donationStatus': 'paid'});
    await batch.commit();
  }

  Future<void> disputeDonationPayment(String donationId, String orderId) async {
    final batch = _db.batch();
    batch.update(_db.collection('donations').doc(donationId), {
      'status': 'pending',
      'disputedAt': FieldValue.serverTimestamp(),
      'paymentMethod': FieldValue.delete(),
    });
    batch.update(_db.collection('orders').doc(orderId), {'donationStatus': 'pending'});
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
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    return snap.docs.map((d) => Restaurant.fromMap(d.id, d.data())).toList();
  }

  Future<void> setRestaurantActive(String restaurantId, bool isActive) =>
      _db.collection('restaurants').doc(restaurantId).update({'isActive': isActive});

  Future<List<Map<String, dynamic>>> getMenuItems(String restaurantId) async {
    final snap = await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .where('isAvailable', isEqualTo: true)
        .get();
    final items = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    items.sort((a, b) => (a['category'] as String? ?? '').compareTo(b['category'] as String? ?? ''));
    return items;
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

  // ─── ORDER CHAT (restaurante ↔ cliente) ───────────────────

  Stream<List<Map<String, dynamic>>> orderChatStream(String orderId) => _db
      .collection('orders')
      .doc(orderId)
      .collection('chat')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> sendOrderChatMessage({
    required String orderId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String text,
  }) =>
      _db.collection('orders').doc(orderId).collection('chat').add({
        'senderId': senderId,
        'senderRole': senderRole,
        'senderName': senderName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ─── DONATION CHAT ────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> donationChatStream(String donationId) => _db
      .collection('donations')
      .doc(donationId)
      .collection('chat')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> sendChatMessage({
    required String donationId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String text,
    String? imageUrl,
  }) =>
      _db.collection('donations').doc(donationId).collection('chat').add({
        'senderId': senderId,
        'senderRole': senderRole,
        'senderName': senderName,
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<Map<String, dynamic>?> donationStream(String donationId) => _db
      .collection('donations')
      .doc(donationId)
      .snapshots()
      .map((s) => s.exists ? {'id': s.id, ...s.data()!} : null);

  // ─── CREDITS ──────────────────────────────────────────────

  /// Stream of credit balance for a restaurant.
  Stream<double> creditBalanceStream(String restaurantId) => _db
      .collection('restaurants')
      .doc(restaurantId)
      .snapshots()
      .map((s) => (s.data()?['creditBalance'] ?? 0.0).toDouble());

  /// Deduct 1% of subtotal as commission when an order is confirmed.
  Future<void> deductCommission(String restaurantId, double subtotal) async {
    final commission = subtotal * 0.01;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snap = await _db.collection('restaurants').doc(restaurantId).get();
    final currentBalance = (snap.data()?['creditBalance'] ?? 0.0).toDouble();
    final newBalance = currentBalance - commission;

    final Map<String, dynamic> updates = {
      'creditBalance': FieldValue.increment(-commission),
    };

    // Set negativeBalanceDate if going negative for the first time today
    if (newBalance <= 0 && currentBalance > 0) {
      updates['negativeBalanceDate'] = Timestamp.fromDate(today);
    }

    await _db.collection('restaurants').doc(restaurantId).update(updates);

    // Log transaction
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('creditTransactions')
        .add({
      'type': 'commission',
      'amount': -commission,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add credits after a successful IAP purchase.
  Future<void> addCredits(
    String restaurantId,
    double amount,
    String transactionId,
    String productId,
  ) async {
    await _db.collection('restaurants').doc(restaurantId).update({
      'creditBalance': FieldValue.increment(amount),
    });
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('creditTransactions')
        .add({
      'type': 'purchase',
      'amount': amount,
      'transactionId': transactionId,
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of the last 30 credit transactions for a restaurant.
  Stream<List<Map<String, dynamic>>> creditTransactionsStream(
          String restaurantId) =>
      _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('creditTransactions')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  // ─── ADMIN ────────────────────────────────────────────────

  /// Devuelve todos los restaurantes (para el panel admin).
  Future<List<Map<String, dynamic>>> adminGetAllRestaurants() async {
    final snap = await _db
        .collection('restaurants')
        .orderBy('name')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Agrega créditos manualmente desde el admin.
  Future<void> adminAddCredits(String restaurantId, double amount, String note) async {
    await _db.collection('restaurants').doc(restaurantId).update({
      'creditBalance': FieldValue.increment(amount),
    });
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('creditTransactions')
        .add({
      'type': 'admin',
      'amount': amount,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Devuelve todas las comisiones con [status] dado, de todos los restaurantes.
  Future<List<Map<String, dynamic>>> getAdminCommissions({
    required String status,
  }) async {
    final snap = await _db
        .collectionGroup('weeks')
        .where('status', isEqualTo: status)
        .orderBy('weekStart', descending: true)
        .get();
    return snap.docs.map((d) {
      final restaurantId = d.reference.parent.parent?.id ?? '';
      return {'weekId': d.id, 'restaurantId': restaurantId, ...d.data()};
    }).toList();
  }

  Future<void> adminConfirmCommission({
    required String restaurantId,
    required String weekId,
  }) =>
      _db
          .collection('commissions')
          .doc(restaurantId)
          .collection('weeks')
          .doc(weekId)
          .update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });

  // ─── DIRECT DONATIONS ─────────────────────────────────────

  Future<String> createDirectDonation({
    required String causeId,
    required String causeName,
    required String customerName,
    required String customerEmail,
    String? customerId,
    required double proposedAmount,
    String? notes,
  }) async {
    final ref = _db.collection('direct_donations').doc();
    await ref.set({
      'causeId': causeId,
      'causeName': causeName,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'proposedAmount': proposedAmount,
      'confirmedAmount': null,
      'status': 'pending',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Map<String, dynamic>>> directDonationsByCauseStream(
          String causeId, String status) =>
      _db
          .collection('direct_donations')
          .where('causeId', isEqualTo: causeId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> directDonationsByCustomerStream(
          String customerId) =>
      _db
          .collection('direct_donations')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> confirmDirectDonation({
    required String donationId,
    required String causeId,
    required double confirmedAmount,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('direct_donations').doc(donationId), {
      'status': 'confirmed',
      'confirmedAmount': confirmedAmount,
      'confirmedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('causes').doc(causeId), {
      'totalRaised': FieldValue.increment(confirmedAmount),
    });
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> directDonationChatStream(String donationId) =>
      _db
          .collection('direct_donations')
          .doc(donationId)
          .collection('chat')
          .orderBy('createdAt')
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> sendDirectDonationChatMessage({
    required String donationId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String text,
    String? imageUrl,
  }) =>
      _db
          .collection('direct_donations')
          .doc(donationId)
          .collection('chat')
          .add({
        'senderId': senderId,
        'senderRole': senderRole,
        'senderName': senderName,
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ─── CAUSE UPDATES ────────────────────────────────────────

  Stream<List<CauseUpdate>> causeUpdatesStream(String causeId) => _db
      .collection('causes')
      .doc(causeId)
      .collection('updates')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => CauseUpdate.fromMap(d.id, d.data())).toList());

  Future<void> addCauseUpdate(String causeId, String message, {String? imageUrl}) =>
      _db.collection('causes').doc(causeId).collection('updates').add({
        'message': message,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> editCauseUpdate(String causeId, String updateId, String message) =>
      _db.collection('causes').doc(causeId).collection('updates').doc(updateId)
          .update({'message': message});

  Future<void> deleteCauseUpdate(String causeId, String updateId) =>
      _db.collection('causes').doc(causeId).collection('updates').doc(updateId).delete();

  // ─── CAUSE RANKING ────────────────────────────────────────

  /// Returns causes ranked by amount raised in the given period.
  /// period: 'all' | 'monthly' | 'weekly'
  Future<List<Map<String, dynamic>>> getCausesRanking({String period = 'all'}) async {
    if (period == 'all') {
      final snap = await _db
          .collection('causes')
          .where('isVerified', isEqualTo: true)
          .orderBy('totalRaised', descending: true)
          .limit(20)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    }

    // For weekly/monthly: aggregate donations from the period
    final now = DateTime.now();
    final from = period == 'weekly'
        ? now.subtract(const Duration(days: 7))
        : DateTime(now.year, now.month, 1);

    final snap = await _db
        .collection('donations')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .get();

    final Map<String, Map<String, dynamic>> map = {};
    for (final doc in snap.docs) {
      final causeId = doc['causeId'] as String? ?? '';
      if (causeId.isEmpty) continue;
      if (!map.containsKey(causeId)) {
        map[causeId] = {
          'id': causeId,
          'causeName': doc['causeName'] ?? '',
          'totalRaised': 0.0,
          'helpersCount': 0,
        };
      }
      map[causeId]!['totalRaised'] =
          (map[causeId]!['totalRaised'] as double) + (doc['amount'] ?? 0.0).toDouble();
      map[causeId]!['helpersCount'] = (map[causeId]!['helpersCount'] as int) + 1;
    }

    // Fetch full cause data to get name, logo, targetAmount
    final ranked = map.values.toList()
      ..sort((a, b) =>
          (b['totalRaised'] as double).compareTo(a['totalRaised'] as double));

    // Enrich with cause docs (batch fetch)
    final causeDocs = await Future.wait(
      ranked.take(20).map((r) => _db.collection('causes').doc(r['id'] as String).get()),
    );
    for (int i = 0; i < causeDocs.length; i++) {
      final doc = causeDocs[i];
      if (doc.exists) {
        ranked[i]['name']         = doc['name'] ?? ranked[i]['causeName'];
        ranked[i]['logo']         = doc.data()?['logo'];
        ranked[i]['targetAmount'] = (doc.data()?['targetAmount'] ?? 0.0).toDouble();
        ranked[i]['description']  = doc.data()?['description'] ?? '';
      }
    }

    return ranked.take(20).toList();
  }
}

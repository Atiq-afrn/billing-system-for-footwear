import 'package:flutter/foundation.dart';

import '../models/bill.dart';
import '../models/bill_draft.dart';
import '../models/company_profile.dart';
import '../models/customer.dart';
import '../models/loyalty_models.dart';
import '../models/product.dart';
import '../models/product_draft.dart';
import '../models/return_models.dart';
import '../models/user_profile.dart';
import '../repositories/shop_repository.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/database_service.dart';
import '../services/excel_export_service.dart';
import '../services/whatsapp_service.dart';

class ShopViewModel extends ChangeNotifier {
  ShopViewModel(
    this._repository,
    this._excelExportService, [
    WhatsAppService? whatsAppService,
    this.databaseService,
  ]) : _whatsAppService = whatsAppService ?? WhatsAppService();

  final ShopRepository _repository;
  final ExcelExportService _excelExportService;
  final WhatsAppService _whatsAppService;
  final DatabaseService? databaseService;
  int selectedTab = 0;
  bool isLoading = false;
  String? error;
  String? lastExportPath;
  List<Product> products = const [];
  List<Customer> customers = const [];
  List<Bill> bills = const [];

  // Loyalty & Offers state
  LoyaltyProgramConfig loyaltyConfig = const LoyaltyProgramConfig();
  Map<String, Map<String, dynamic>> customerLoyaltyData = {};
  List<Offer> offers = const [];
  List<OfferTracking> offerTracking = const [];

  // Returns & Exchanges state
  List<ReturnRecord> returns = const [];
  List<StockMovement> stockMovements = const [];

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? selectedDate;

  final List<String> _categories = [];

  static const List<String> defaultCategories = [
    'Men Formal',
    'Men Casual',
    'Men Sports',
    'Women Heels',
    'Women Flats',
    'Women Sandals',
    'Kids',
    'Accessories',
  ];

  List<String> get allCategories {
    if (_categories.isEmpty) {
      final set = <String>{...defaultCategories};
      for (final p in products) {
        if (p.category.trim().isNotEmpty) set.add(p.category.trim());
      }
      return set.toList();
    }
    return List.unmodifiable(_categories);
  }

  Future<void> loadCategories() async {
    try {
      final list = await _repository.fetchCategories();
      if (list.isEmpty) {
        _categories.clear();
        _categories.addAll(defaultCategories);
        for (final cat in defaultCategories) {
          await _repository.addCategory(cat);
        }
      } else {
        _categories.clear();
        _categories.addAll(list);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addCustomCategory(String category) async {
    final clean = category.trim();
    if (clean.isNotEmpty && !_categories.any((c) => c.toLowerCase() == clean.toLowerCase())) {
      _categories.add(clean);
      try {
        await _repository.addCategory(clean);
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<void> removeCategory(String category) async {
    final clean = category.trim();
    _categories.removeWhere((c) => c.toLowerCase() == clean.toLowerCase());
    notifyListeners();
    try {
      await _repository.deleteCategory(clean);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateUpiId(String newUpi) async {
    await AuthService.instance.updateProfile(upiId: newUpi.trim());
    CloudSyncService.instance.ensureCompanyProfile(currentCompanyProfile);
    notifyListeners();
  }

  UserProfile? get userProfile => AuthService.instance.currentProfile;
  String get companyName =>
      AuthService.instance.activeCompany?.name ??
      (userProfile != null && userProfile!.companyName.trim().isNotEmpty
          ? userProfile!.companyName.trim()
          : 'Ayesha Footwear');

  String get upiId =>
      AuthService.instance.activeCompany?.upiId ??
      (userProfile != null && userProfile!.upiId.trim().isNotEmpty
          ? userProfile!.upiId.trim()
          : 'atiqullahkhan554@okicici');

  String get companyId => AuthService.instance.activeCompanyId;

  CompanyProfile get currentCompanyProfile =>
      AuthService.instance.activeCompany ??
      CompanyProfile(
        id: companyId,
        name: companyName,
        ownerUid: userProfile?.uid ?? '',
        mobile: userProfile?.mobile ?? '',
        upiId: upiId,
        createdAt: userProfile?.createdAt ?? DateTime.now(),
      );

  CloudSyncStatus get cloudSyncStatus => CloudSyncService.instance.status;
  DateTime? get lastSyncedAt => CloudSyncService.instance.lastSyncedAt;

  int get todaySales => todayBills.fold(0, (sum, bill) => sum + bill.total);
  int get totalStock => products.fold(0, (sum, product) => sum + product.stock);

  List<Product> get outOfStockProducts => products.where((p) => p.stock <= 0).toList();
  List<Product> get lowStockProducts => products.where((p) => p.stock > 0 && p.stock <= 3).toList();
  int get finishedStockCount => outOfStockProducts.length;

  List<Bill> get todayBills {
    final now = DateTime.now();
    return bills.where((bill) =>
        bill.time.year == now.year &&
        bill.time.month == now.month &&
        bill.time.day == now.day).toList();
  }

  // ---------------------------------------------------------------------------
  // MONTH FILTERING & ANALYTICS
  // ---------------------------------------------------------------------------
  List<DateTime> get availableMonths {
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    final set = <DateTime>{current};
    for (int i = 1; i <= 6; i++) {
      set.add(DateTime(current.year, current.month - i));
    }
    for (final b in bills) {
      set.add(DateTime(b.time.year, b.time.month));
    }
    final list = set.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  void setSelectedMonth(DateTime month) {
    selectedMonth = DateTime(month.year, month.month);
    selectedDate = null;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    selectedDate = date;
    if (date != null) {
      selectedMonth = DateTime(date.year, date.month);
    }
    notifyListeners();
  }

  List<Bill> get billsForSelectedDate {
    final target = selectedDate ?? DateTime.now();
    return bills.where((b) =>
        b.time.year == target.year &&
        b.time.month == target.month &&
        b.time.day == target.day).toList();
  }

  int get salesForSelectedDate =>
      billsForSelectedDate.fold(0, (sum, b) => sum + b.total);

  DateTime get previousMonth => DateTime(selectedMonth.year, selectedMonth.month - 1);

  List<Bill> get billsForSelectedMonth => bills.where((b) =>
      b.time.year == selectedMonth.year && b.time.month == selectedMonth.month).toList();

  List<Bill> get billsForPreviousMonth => bills.where((b) =>
      b.time.year == previousMonth.year && b.time.month == previousMonth.month).toList();

  int get netSalesSelectedMonth =>
      billsForSelectedMonth.fold(0, (sum, b) => sum + b.total);

  int get netSalesPreviousMonth =>
      billsForPreviousMonth.fold(0, (sum, b) => sum + b.total);

  double get netSalesPercentChange =>
      _calcPercent(netSalesSelectedMonth, netSalesPreviousMonth);

  int get completedBillsSelectedMonth => billsForSelectedMonth.length;
  double get completedBillsPercentChange =>
      _calcPercent(completedBillsSelectedMonth, billsForPreviousMonth.length);

  int get itemsSoldSelectedMonth =>
      billsForSelectedMonth.fold(0, (sum, b) => sum + b.qty);
  double get itemsSoldPercentChange => _calcPercent(
      itemsSoldSelectedMonth,
      billsForPreviousMonth.fold(0, (sum, b) => sum + b.qty));

  int get averageBillValueSelectedMonth {
    if (completedBillsSelectedMonth == 0) return 0;
    return (netSalesSelectedMonth / completedBillsSelectedMonth).round();
  }

  int get averageBillValuePreviousMonth {
    if (billsForPreviousMonth.isEmpty) return 0;
    return (netSalesPreviousMonth / billsForPreviousMonth.length).round();
  }

  double get averageBillValuePercentChange =>
      _calcPercent(averageBillValueSelectedMonth, averageBillValuePreviousMonth);

  int get grossProfitSelectedMonth => (netSalesSelectedMonth * 0.235).round();
  int get grossProfitPreviousMonth => (netSalesPreviousMonth * 0.235).round();
  double get grossProfitPercentChange =>
      _calcPercent(grossProfitSelectedMonth, grossProfitPreviousMonth);

  double _calcPercent(num current, num previous) {
    if (previous == 0) {
      return current > 0 ? 100.0 : 0.0;
    }
    return ((current - previous) / previous) * 100.0;
  }

  // ---------------------------------------------------------------------------
  // DAILY CHART DATA (Day -> Value)
  // ---------------------------------------------------------------------------
  Map<int, int> getDailyMetric(DateTime month, {required String metric}) {
    final map = <int, int>{};
    for (int day = 1; day <= 31; day++) {
      map[day] = 0;
    }
    final targetBills = bills.where((b) =>
        b.time.year == month.year && b.time.month == month.month);

    for (final b in targetBills) {
      final day = b.time.day;
      if (metric == 'Sales') {
        map[day] = (map[day] ?? 0) + b.total;
      } else if (metric == 'Items') {
        map[day] = (map[day] ?? 0) + b.qty;
      } else {
        map[day] = (map[day] ?? 0) + 1;
      }
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // TOP SELLING PRODUCTS
  // ---------------------------------------------------------------------------
  List<TopProductSale> get topSellingProducts {
    final Map<String, TopProductSale> map = {};
    final relevantBills = billsForSelectedMonth;

    for (final b in relevantBills) {
      for (final it in b.allItems) {
        final key = '${it.productName}_${it.size}_${it.color}';
        final existing = map[key];
        if (existing == null) {
          map[key] = TopProductSale(
            productId: it.productId,
            name: it.productName,
            size: it.size,
            color: it.color,
            quantity: it.qty,
            revenue: it.total,
          );
        } else {
          map[key] = existing.copyWith(
            quantity: existing.quantity + it.qty,
            revenue: existing.revenue + it.total,
          );
        }
      }
    }

    final list = map.values.toList();
    list.sort((a, b) => b.quantity.compareTo(a.quantity));
    return list.take(5).toList();
  }

  Product? findProductById(String id) {
    final matches = products.where((p) => p.id == id);
    if (matches.isNotEmpty) return matches.first;
    return null;
  }

  // ---------------------------------------------------------------------------
  // CUSTOMER LOOKUPS & MONTHLY FILTERING
  // ---------------------------------------------------------------------------
  List<Customer> getCustomersForMonth(DateTime? month) {
    if (month == null) return customers;
    final customerMobilesInMonth = bills
        .where((b) => b.time.year == month.year && b.time.month == month.month)
        .map((b) => b.mobile)
        .toSet();

    return customers.where((c) => customerMobilesInMonth.contains(c.mobile)).toList();
  }

  List<Bill> getBillsForCustomer(Customer customer) {
    return bills.where((b) =>
        b.customerId == customer.id ||
        (b.mobile.isNotEmpty && b.mobile == customer.mobile)).toList();
  }

  // ---------------------------------------------------------------------------
  // LOYALTY & OFFERS COMPUTED PROFILES & METRICS
  // ---------------------------------------------------------------------------
  List<CustomerLoyaltyProfile> get customerLoyaltyProfiles {
    return customers.map((c) {
      final cBills = getBillsForCustomer(c);
      final loyaltyMap = customerLoyaltyData[c.id];
      final points = (loyaltyMap?['points'] as num?)?.toInt() ??
          // Fallback if not yet recorded: calculate from total spend + welcome bonus
          (loyaltyConfig.welcomeBonusPoints +
              ((c.totalSpent / 100).floor() * loyaltyConfig.pointsPer100Spent));
      final pointsRedeemed = (loyaltyMap?['points_redeemed'] as num?)?.toInt() ?? 0;
      final consent = ((loyaltyMap?['marketing_consent'] as num?)?.toInt() ?? 1) == 1;

      return CustomerLoyaltyProfile(
        customer: c,
        bills: cBills,
        points: points,
        pointsRedeemed: pointsRedeemed,
        marketingConsent: consent,
        config: loyaltyConfig,
      );
    }).toList();
  }

  int get loyalCustomerCount =>
      customerLoyaltyProfiles.where((p) => p.segment == CustomerSegment.loyal).length;

  int get highSpendingCustomerCount =>
      customerLoyaltyProfiles.where((p) => p.segment == CustomerSegment.highSpending).length;

  int get regularCustomerCount =>
      customerLoyaltyProfiles.where((p) => p.segment == CustomerSegment.regular).length;

  int get newCustomerCount =>
      customerLoyaltyProfiles.where((p) => p.segment == CustomerSegment.newCustomer).length;

  int get inactiveCustomerCount =>
      customerLoyaltyProfiles.where((p) => p.segment == CustomerSegment.inactive).length;

  double get repeatPurchaseRate {
    if (customers.isEmpty) return 0.0;
    final repeats = customerLoyaltyProfiles.where((p) => p.totalBills >= 2).length;
    return (repeats / customers.length) * 100.0;
  }

  int get totalLoyaltyPointsIssued =>
      customerLoyaltyProfiles.fold(0, (sum, p) => sum + p.points);

  int get totalLoyaltyPointsRedeemed =>
      customerLoyaltyProfiles.fold(0, (sum, p) => sum + p.pointsRedeemed);

  List<CustomerLoyaltyProfile> get topLoyalCustomersBySpending {
    final list = [...customerLoyaltyProfiles];
    list.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return list.take(8).toList();
  }

  List<Offer> get activeOffers => offers.where((o) => o.isCurrentlyValid).toList();

  Future<void> updateLoyaltyConfig(LoyaltyProgramConfig newConfig) async {
    loyaltyConfig = newConfig;
    await _repository.saveLoyaltyConfig(newConfig);
    notifyListeners();
  }

  Future<void> updateCustomerLoyaltyConsent(String customerId, bool consent) async {
    await _repository.updateCustomerLoyalty(
      customerId: customerId,
      marketingConsent: consent,
    );
    customerLoyaltyData = await _repository.fetchAllCustomerLoyaltyData();
    notifyListeners();
  }

  Future<void> adjustCustomerPoints(String customerId, int newPoints, String note) async {
    await _repository.updateCustomerLoyalty(
      customerId: customerId,
      points: newPoints,
      notes: note,
    );
    customerLoyaltyData = await _repository.fetchAllCustomerLoyaltyData();
    notifyListeners();
  }

  Future<void> saveOffer(Offer offer) async {
    await _repository.saveOffer(offer);
    offers = await _repository.fetchOffers();
    notifyListeners();
  }

  Future<void> deleteOffer(String offerId) async {
    await _repository.deleteOffer(offerId);
    offers = await _repository.fetchOffers();
    notifyListeners();
  }

  Future<bool> sendPersonalizedOffer(CustomerLoyaltyProfile profile, Offer offer) async {
    final launched = await _whatsAppService.sendPersonalizedOffer(
      profile: profile,
      offer: offer,
      companyName: companyName,
    );

    if (launched) {
      final tracking = OfferTracking(
        id: 'TRACK-${DateTime.now().millisecondsSinceEpoch}',
        offerId: offer.id,
        offerCode: offer.code,
        customerId: profile.customer.id,
        customerName: profile.customer.name,
        mobile: profile.customer.mobile,
        sentAt: DateTime.now(),
      );
      await _repository.recordOfferSent(tracking);
      offerTracking = await _repository.fetchOfferTracking();
      notifyListeners();
    }
    return launched;
  }

  Future<void> markOfferRedeemed(String trackingId, String billId, int salesAmount) async {
    await _repository.recordOfferRedeemed(
      trackingId: trackingId,
      billId: billId,
      salesAmount: salesAmount,
    );
    offerTracking = await _repository.fetchOfferTracking();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // RETURNS & EXCHANGES COMPUTED METRICS & HELPERS
  // ---------------------------------------------------------------------------
  int get totalReturnsCount =>
      returns.where((r) => r.type == ReturnType.returnOnly).length;

  int get totalExchangesCount =>
      returns.where((r) => r.type == ReturnType.exchange).length;

  int get pendingApprovalCount =>
      returns.where((r) => r.status == ReturnStatus.pendingApproval).length;

  int get totalRefundsDisbursed => returns
      .where((r) =>
          r.isCustomerRefund &&
          (r.status == ReturnStatus.approved || r.status == ReturnStatus.completed))
      .fold(0, (sum, r) => sum + r.customerRefundAmount);

  int get totalExchangeNetPaid => returns
      .where((r) =>
          r.isCustomerPayable &&
          (r.status == ReturnStatus.approved || r.status == ReturnStatus.completed))
      .fold(0, (sum, r) => sum + r.customerPayableAmount);

  int get damagedStockItemsCount {
    return returns
        .where((r) => r.status == ReturnStatus.approved || r.status == ReturnStatus.completed)
        .expand((r) => r.items)
        .where((it) =>
            it.condition == ProductCondition.damaged ||
            it.condition == ProductCondition.defective ||
            it.condition == ProductCondition.used)
        .fold(0, (sum, it) => sum + it.qty);
  }

  Map<String, int> get returnReasonsBreakdown {
    final map = <String, int>{};
    for (final r in returns) {
      final reason = r.returnReason.isNotEmpty ? r.returnReason : 'Other';
      map[reason] = (map[reason] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get mostReturnedProducts {
    final map = <String, int>{};
    for (final r in returns) {
      for (final it in r.items) {
        map[it.productName] = (map[it.productName] ?? 0) + it.qty;
      }
    }
    return map;
  }

  int getEligibleReturnQty(Bill bill, String productId, String size, String color) {
    // 1. Total purchased in this bill
    final matchingItems = bill.allItems.where((it) =>
        it.productId == productId &&
        it.size.trim() == size.trim() &&
        it.color.trim() == color.trim());
    final int originalQty = matchingItems.fold(0, (sum, it) => sum + it.qty);
    if (originalQty <= 0) return 0;

    // 2. Total already returned or exchanged on non-rejected records
    final activeReturns = returns.where(
        (r) => r.billId == bill.id && r.status != ReturnStatus.rejected);
    final int alreadyReturned = activeReturns
        .expand((r) => r.items)
        .where((it) =>
            it.productId == productId &&
            it.size.trim() == size.trim() &&
            it.color.trim() == color.trim())
        .fold(0, (sum, it) => sum + it.qty);

    final eligible = originalQty - alreadyReturned;
    return eligible < 0 ? 0 : eligible;
  }

  Future<void> processReturnOrExchange(ReturnRecord record) async {
    await _repository.createReturnOrExchange(record);
    await refresh();
    notifyListeners();
  }

  Future<void> updateReturnStatus(
    String returnId,
    ReturnStatus status, {
    String? rejectionReason,
  }) async {
    final adminName = (userProfile?.name != null && userProfile!.name.trim().isNotEmpty)
        ? userProfile!.name.trim()
        : 'Store Owner';

    await _repository.updateReturnStatus(
      returnId: returnId,
      status: status,
      approvedBy: adminName,
      rejectionReason: rejectionReason,
    );
    await refresh();
    notifyListeners();
  }

  Future<bool> sendReturnReceiptWhatsApp(ReturnRecord record) async {
    return await _whatsAppService.sendReturnExchangeReceiptWhatsApp(
      record: record,
      companyName: companyName,
    );
  }

  // ---------------------------------------------------------------------------
  // INITIALIZATION & LIFECYCLE
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    try {
      CloudSyncService.instance.removeListener(_onSyncChanged);
      CloudSyncService.instance.addListener(_onSyncChanged);
      AuthService.instance.removeListener(_onAuthChanged);
      AuthService.instance.addListener(_onAuthChanged);

      if (databaseService != null) {
        final db = await databaseService!.database;
        await databaseService!.seedCompanyDefaults(db, companyId);
      }

      await refresh();
      error = null;

      // Start real-time Firestore synchronization
      _setupFirestoreRealtimeListeners();

      // Asynchronous non-blocking cloud synchronization
      _triggerBackgroundCloudSync();
    } catch (_) {
      error = 'Unable to load shop data';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _setupFirestoreRealtimeListeners() {
    if (databaseService == null) return;
    CloudSyncService.instance.startRealtimeSync(
      companyId: companyId,
      databaseService: databaseService!,
      onDataRefreshed: () async {
        await refresh();
        notifyListeners();
      },
      onCompanyRefreshed: (map) {
        final name = (map['name'] ?? map['companyName']) as String?;
        final upi = (map['upiId'] ?? map['upi_id']) as String?;
        final mobile = (map['mobile'] ?? map['phone']) as String?;
        if ((name != null && name.trim().isNotEmpty && name.trim() != companyName) ||
            (upi != null && upi.trim().isNotEmpty && upi.trim() != upiId)) {
          AuthService.instance.updateProfile(
            companyName: name?.trim(),
            upiId: upi?.trim(),
            mobile: mobile?.trim(),
          );
        }
      },
    );
  }

  void _onSyncChanged() {
    notifyListeners();
  }

  void _onAuthChanged() {
    if (AuthService.instance.isAuthenticated) {
      _setupFirestoreRealtimeListeners();
    } else {
      CloudSyncService.instance.stopRealtimeListeners();
    }
    notifyListeners();
  }

  void _triggerBackgroundCloudSync() {
    Future(() async {
      await syncWithCloud();
    });
  }

  Future<void> refreshUserProfile() async {
    await onUserAuthenticated();
  }

  Future<void> onUserAuthenticated() async {
    isLoading = true;
    notifyListeners();
    try {
      if (databaseService != null) {
        final db = await databaseService!.database;
        await databaseService!.seedCompanyDefaults(db, companyId);
      }

      // Connect real-time listeners for this authenticated user's company and root products
      _setupFirestoreRealtimeListeners();

      // Pull from Firestore to populate local SQLite and restore images
      await syncWithCloud();

      // Refresh local UI state
      await refresh();
      error = null;
    } catch (e) {
      debugPrint('Error on user authentication sync: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> syncWithCloud() async {
    if (databaseService == null) return false;
    final success = await CloudSyncService.instance.syncAll(
      companyId: companyId,
      databaseService: databaseService!,
      companyProfile: currentCompanyProfile,
    );
    if (success) {
      await refresh();
      notifyListeners();
    }
    return success;
  }

  Future<List<CompanyProfile>> fetchOwnerCompanies() async {
    final list = await AuthService.instance.fetchAuthorizedCompanies();
    if (list.isEmpty) return [currentCompanyProfile];
    return list;
  }

  void _clearInMemoryData() {
    products = const [];
    customers = const [];
    bills = const [];
    returns = const [];
    offers = const [];
    offerTracking = const [];
    customerLoyaltyData = {};
    stockMovements = const [];
    _categories.clear();
  }

  Future<void> switchCompany(CompanyProfile company) async {
    // 1. Stop existing realtime listeners to decouple from previous company
    CloudSyncService.instance.stopRealtimeListeners();

    // 2. Clear in-memory company data completely to prevent cross-company data leakage
    _clearInMemoryData();
    notifyListeners();

    // 3. Set active company in AuthService (persists in SharedPreferences)
    await AuthService.instance.selectCompany(company);

    // 4. Ensure starter footwear defaults and categories exist for this store
    if (databaseService != null) {
      final db = await databaseService!.database;
      await databaseService!.seedCompanyDefaults(db, company.id);
    }

    // 5. Connect realtime Firestore listeners for the new company
    _setupFirestoreRealtimeListeners();

    // 6. Load isolated records for the new company from SQLite
    await refresh();

    // 7. Trigger two-way sync for the new company
    await syncWithCloud();

    notifyListeners();
  }

  Future<void> createAndSwitchCompany({
    required String name,
    required String upiId,
    String mobile = '',
    String address = '',
  }) async {
    final newCompany = await AuthService.instance.registerNewBranch(
      name: name,
      upiId: upiId,
      mobile: mobile,
      address: address,
    );
    await switchCompany(newCompany);
  }

  Future<void> logout() async {
    CloudSyncService.instance.stopRealtimeListeners();
    _clearInMemoryData();
    await AuthService.instance.logout();
    notifyListeners();
  }

  @override
  void dispose() {
    CloudSyncService.instance.stopRealtimeListeners();
    CloudSyncService.instance.removeListener(_onSyncChanged);
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> refresh() async {
    products = await _repository.fetchProducts();
    customers = await _repository.fetchCustomers();
    bills = await _repository.fetchBills();
    await loadCategories();

    // Loyalty data
    try {
      loyaltyConfig = await _repository.fetchLoyaltyConfig();
      customerLoyaltyData = await _repository.fetchAllCustomerLoyaltyData();
      offers = await _repository.fetchOffers();
      offerTracking = await _repository.fetchOfferTracking();
    } catch (_) {}

    // Returns data
    try {
      returns = await _repository.fetchReturns();
      stockMovements = await _repository.fetchStockMovements();
    } catch (_) {}
  }

  void setTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  List<Customer> searchCustomers(String query, {DateTime? month}) {
    final baseList = getCustomersForMonth(month);
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) return baseList;
    return baseList.where((customer) {
      final searchable =
          '${customer.id} ${customer.name} ${customer.mobile} ${customer.size} ${customer.colors} ${customer.lastItem}'
              .toLowerCase();
      return searchable.contains(normalized);
    }).toList();
  }

  List<Product> searchProducts(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) return products;
    return products.where((product) {
      final searchable =
          '${product.id} ${product.name} ${product.category} ${product.sizes.join(' ')} ${product.colors.join(' ')}'
              .toLowerCase();
      return searchable.contains(normalized);
    }).toList();
  }

  Future<void> createBill(BillDraft draft) async {
    await _repository.saveBill(draft);
    await refresh();
    notifyListeners();
  }

  Future<void> addProduct(ProductDraft draft) async {
    await _repository.saveProduct(draft);
    products = await _repository.fetchProducts();
    stockMovements = await _repository.fetchStockMovements();
    notifyListeners();
  }

  Future<void> restockProduct(String productId, int newStock) async {
    await _repository.updateProductStock(productId, newStock);
    products = await _repository.fetchProducts();
    stockMovements = await _repository.fetchStockMovements();
    notifyListeners();
  }

  Future<String> exportExcel() async {
    await refresh();
    final path = await _excelExportService.exportShopData(
      customers: customers,
      products: products,
      bills: bills,
      companyName: companyName,
    );
    lastExportPath = path;
    notifyListeners();
    return path;
  }

  Future<String> exportMonthlyBills(DateTime month) async {
    await refresh();
    final targetBills = bills.where((b) =>
        b.time.year == month.year && b.time.month == month.month).toList();
    final path = await _excelExportService.exportMonthlyBills(
      bills: targetBills,
      month: month,
      companyName: companyName,
    );
    lastExportPath = path;
    notifyListeners();
    return path;
  }

  Future<bool> sendBillWhatsApp(Bill bill) async {
    return await _whatsAppService.sendBillWhatsApp(bill, companyName: companyName);
  }

  Future<bool> sendCustomerOffer(Customer customer) async {
    return await _whatsAppService.sendCustomerOffer(customer, companyName: companyName);
  }

  Future<void> shareExcelFile(String path) async {
    await _whatsAppService.shareExcelFile(path);
  }
}

class TopProductSale {
  const TopProductSale({
    required this.productId,
    required this.name,
    required this.size,
    required this.color,
    required this.quantity,
    required this.revenue,
  });

  final String productId;
  final String name;
  final String size;
  final String color;
  final int quantity;
  final int revenue;

  TopProductSale copyWith({
    String? productId,
    String? name,
    String? size,
    String? color,
    int? quantity,
    int? revenue,
  }) {
    return TopProductSale(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      size: size ?? this.size,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      revenue: revenue ?? this.revenue,
    );
  }
}

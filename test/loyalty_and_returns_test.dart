import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayesha_footwear/models/bill.dart';
import 'package:ayesha_footwear/models/bill_draft.dart';
import 'package:ayesha_footwear/models/bill_item.dart';
import 'package:ayesha_footwear/models/customer.dart';
import 'package:ayesha_footwear/models/loyalty_models.dart';
import 'package:ayesha_footwear/models/product.dart';
import 'package:ayesha_footwear/models/return_models.dart';
import 'package:ayesha_footwear/repositories/shop_repository.dart';
import 'package:ayesha_footwear/services/excel_export_service.dart';
import 'package:ayesha_footwear/services/whatsapp_service.dart';
import 'package:ayesha_footwear/view_models/shop_view_model.dart';
import 'package:ayesha_footwear/views/loyal_customers_offers_view.dart';
import 'package:ayesha_footwear/views/returns_exchanges_view.dart';
import 'package:ayesha_footwear/widgets/shop_drawer.dart';

class MockShopRepository implements ShopRepository {
  List<Product> products = [
    const Product(
      id: 'P1',
      name: 'Leather Shoes',
      category: 'Men Formal',
      stock: 10,
      price: 2000,
      sizes: ['8', '9'],
      colors: ['Black'],
    ),
    const Product(
      id: 'P2',
      name: 'Running Sneakers',
      category: 'Men Sports',
      stock: 5,
      price: 2500,
      sizes: ['8', '9'],
      colors: ['White'],
    ),
  ];

  List<Customer> customers = [
    const Customer(
      id: 'C1',
      name: 'Faizan Khan',
      mobile: '9876543210',
      size: '8',
      colors: 'Black',
      lastItem: 'Leather Shoes',
      totalSpent: 6000,
      visits: 4,
    ),
    const Customer(
      id: 'C2',
      name: 'Zaid Sheikh',
      mobile: '9123456789',
      size: '9',
      colors: 'White',
      lastItem: 'Running Sneakers',
      totalSpent: 2500,
      visits: 1,
    ),
  ];

  List<Bill> bills = [
    Bill(
      id: 'BILL-001',
      customerId: 'C1',
      productId: 'P1',
      customer: 'Faizan Khan',
      mobile: '9876543210',
      item: 'Leather Shoes',
      size: '8',
      color: 'Black',
      qty: 2,
      price: 3000,
      discount: 0,
      total: 6000,
      payMode: 'Cash',
      note: '',
      time: DateTime.now().subtract(const Duration(days: 2)),
      items: const [
        BillItem(productId: 'P1', productName: 'Leather Shoes', size: '8', color: 'Black', qty: 2, price: 3000),
      ],
    ),
  ];

  LoyaltyProgramConfig loyaltyConfig = const LoyaltyProgramConfig();
  Map<String, Map<String, dynamic>> loyaltyData = {};
  List<Offer> offers = [];
  List<OfferTracking> offerTracking = [];
  List<ReturnRecord> returns = [];
  List<StockMovement> stockMovements = [];

  @override
  Future<List<Product>> fetchProducts() async => products;
  @override
  Future<List<Customer>> fetchCustomers() async => customers;
  @override
  Future<List<Bill>> fetchBills() async => bills;
  @override
  Future<Bill> saveBill(BillDraft draft) async => bills.first;
  @override
  Future<Product> saveProduct(dynamic draft) async => products.first;
  @override
  Future<void> deleteProduct(String productId) async {
    products.removeWhere((p) => p.id == productId);
  }
  @override
  Future<void> updateProductStock(String productId, int newStock) async {
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      products[idx] = products[idx].copyWith(stock: newStock);
    }
  }
  @override
  Future<List<String>> fetchCategories() async => ['Men Formal', 'Men Sports'];
  @override
  Future<void> addCategory(String name) async {}
  @override
  Future<void> deleteCategory(String name) async {}

  @override
  Future<LoyaltyProgramConfig> fetchLoyaltyConfig() async => loyaltyConfig;
  @override
  Future<void> saveLoyaltyConfig(LoyaltyProgramConfig config) async {
    loyaltyConfig = config;
  }
  @override
  Future<Map<String, Map<String, dynamic>>> fetchAllCustomerLoyaltyData() async => loyaltyData;
  @override
  Future<void> updateCustomerLoyalty({
    required String customerId,
    int? points,
    int? pointsRedeemed,
    bool? marketingConsent,
    String? notes,
  }) async {
    loyaltyData[customerId] = {
      'customer_id': customerId,
      'points': points ?? 50,
      'points_redeemed': pointsRedeemed ?? 0,
      'marketing_consent': (marketingConsent ?? true) ? 1 : 0,
      'notes': notes ?? '',
    };
  }
  @override
  Future<List<Offer>> fetchOffers() async => offers;
  @override
  Future<void> saveOffer(Offer offer) async {
    offers.removeWhere((o) => o.id == offer.id);
    offers.add(offer);
  }
  @override
  Future<void> deleteOffer(String offerId) async {
    offers.removeWhere((o) => o.id == offerId);
  }
  @override
  Future<List<OfferTracking>> fetchOfferTracking() async => offerTracking;
  @override
  Future<void> recordOfferSent(OfferTracking tracking) async {
    offerTracking.add(tracking);
  }
  @override
  Future<void> recordOfferRedeemed({required String trackingId, required String billId, required int salesAmount}) async {}

  @override
  Future<List<ReturnRecord>> fetchReturns() async => returns;
  @override
  Future<ReturnRecord> createReturnOrExchange(ReturnRecord returnRecord) async {
    returns.add(returnRecord);
    return returnRecord;
  }
  @override
  Future<void> updateReturnStatus({
    required String returnId,
    required ReturnStatus status,
    required String approvedBy,
    String? rejectionReason,
  }) async {
    final idx = returns.indexWhere((r) => r.id == returnId);
    if (idx != -1) {
      returns[idx] = returns[idx].copyWith(status: status, approvedBy: approvedBy, rejectionReason: rejectionReason);
    }
  }
  @override
  Future<List<StockMovement>> fetchStockMovements() async => stockMovements;
  @override
  Future<void> recordStockMovement(StockMovement movement) async {
    stockMovements.add(movement);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockShopRepository mockRepo;
  late ShopViewModel viewModel;

  setUp(() async {
    mockRepo = MockShopRepository();
    viewModel = ShopViewModel(mockRepo, ExcelExportService(), WhatsAppService());
    await viewModel.initialize();
  });

  group('Loyal Customer & Segmentation Tests', () {
    test('Customer segmentation categorizes VIP, Loyal, and New accurately', () {
      final profiles = viewModel.customerLoyaltyProfiles;
      expect(profiles.length, 2);

      // Faizan Khan: Total Spent 6000 >= 5000 -> High Spending VIP
      final faizan = profiles.firstWhere((p) => p.customer.name == 'Faizan Khan');
      expect(faizan.segment, CustomerSegment.highSpending);

      // Zaid Sheikh: Visits 1, total spent 2500 -> New Customer
      final zaid = profiles.firstWhere((p) => p.customer.name == 'Zaid Sheikh');
      expect(zaid.segment, CustomerSegment.newCustomer);
    });

    test('Offer model validates code and generates personalized WhatsApp text', () {
      final offer = Offer(
        id: 'O1',
        code: 'FESTIVE20',
        title: 'Diwali Special Footwear',
        discountType: 'percentage',
        discountValue: 20,
        minSpend: 1500,
        applicableCategory: 'Men Formal',
        targetSegment: 'All',
        validFrom: DateTime.now().subtract(const Duration(days: 1)),
        validUntil: DateTime.now().add(const Duration(days: 10)),
        messageTemplate: '',
      );

      expect(offer.isCurrentlyValid, isTrue);
      expect(offer.discountBadge, '20% OFF');

      final msg = offer.generateMessage(
        customerName: 'Faizan Khan',
        shopName: 'Ayesha Footwear',
        preferredSize: '8',
      );

      expect(msg.contains('FESTIVE20'), isTrue);
      expect(msg.contains('Faizan Khan'), isTrue);
      expect(msg.contains('20% OFF'), isTrue);
    });
  });

  group('Return and Exchange Management Tests', () {
    test('Calculates eligible return quantity correctly avoiding duplicate returns', () {
      final bill = mockRepo.bills.first;
      // Original bill has 2 items of P1
      final eligibleInitially = viewModel.getEligibleReturnQty(bill, 'P1', '8', 'Black');
      expect(eligibleInitially, 2);

      // Record a return of 1 item
      final returnRec = ReturnRecord(
        id: 'RET-01',
        billId: bill.id,
        customerId: bill.customerId,
        customerName: bill.customer,
        mobile: bill.mobile,
        type: ReturnType.returnOnly,
        status: ReturnStatus.completed,
        returnReason: 'Wrong Size',
        productCondition: ProductCondition.sellable,
        returnedTotalAmount: 2000,
        exchangeTotalAmount: 0,
        netAmount: -2000,
        refundMethod: 'Cash',
        refundStatus: 'Completed',
        approvedBy: 'Store Owner',
        createdAt: DateTime.now(),
        items: const [
          ReturnItem(
            productId: 'P1',
            productName: 'Leather Shoes',
            size: '8',
            color: 'Black',
            qty: 1,
            unitPrice: 2000,
            reason: 'Wrong Size',
            condition: ProductCondition.sellable,
          ),
        ],
      );

      viewModel.returns = [returnRec];

      // Remaining eligible return quantity must now be 1 (2 - 1)
      final remainingEligible = viewModel.getEligibleReturnQty(bill, 'P1', '8', 'Black');
      expect(remainingEligible, 1);
    });

    test('Exchange calculates customer balance due vs refund accurately', () {
      // Returned item: 2000; Replacement item: 2500 -> Customer needs to pay 500 extra
      const returnedValue = 2000;
      const exchangeValue = 2500;
      const netAmount = exchangeValue - returnedValue; // 500 (Customer Payable)

      final exchangeRec = ReturnRecord(
        id: 'RET-EXCH-01',
        billId: 'BILL-001',
        customerId: 'C1',
        customerName: 'Faizan Khan',
        mobile: '9876543210',
        type: ReturnType.exchange,
        status: ReturnStatus.completed,
        returnReason: 'Wrong Size',
        productCondition: ProductCondition.sellable,
        returnedTotalAmount: returnedValue,
        exchangeTotalAmount: exchangeValue,
        netAmount: netAmount,
        refundMethod: 'Cash',
        refundStatus: 'Completed',
        approvedBy: 'Store Owner',
        createdAt: DateTime.now(),
        items: const [
          ReturnItem(
            productId: 'P1',
            productName: 'Leather Shoes',
            size: '8',
            color: 'Black',
            qty: 1,
            unitPrice: 2000,
            reason: 'Wrong Size',
            condition: ProductCondition.sellable,
          ),
        ],
        exchangeItems: const [
          ExchangeItem(
            productId: 'P2',
            productName: 'Running Sneakers',
            size: '9',
            color: 'White',
            qty: 1,
            unitPrice: 2500,
          ),
        ],
      );

      expect(exchangeRec.isExchange, isTrue);
      expect(exchangeRec.isCustomerPayable, isTrue);
      expect(exchangeRec.customerPayableAmount, 500);
      expect(exchangeRec.isCustomerRefund, isFalse);
    });
  });

  group('Side Drawer Navigation Integration Tests', () {
    testWidgets('ShopDrawer displays both options and navigates to screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: ShopDrawer(
              viewModel: viewModel,
              onSelectTab: (_) {},
              onExportExcel: () {},
              onPreviewPdf: () {},
              onSendOffer: () {},
              onOpenQrScanner: () {},
            ),
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      // Verify option 1: Loyal Customers & Offers
      expect(find.text('Loyal Customers & Offers'), findsOneWidget);

      // Verify option 2: Returns & Exchanges
      expect(find.text('Returns & Exchanges'), findsOneWidget);

      // Tap Loyal Customers & Offers
      await tester.tap(find.text('Loyal Customers & Offers'));
      await tester.pumpAndSettle();

      // Verify Loyal Customers view is opened
      expect(find.byType(LoyalCustomersOffersView), findsOneWidget);
      expect(find.text('Customers & VIP'), findsOneWidget);
      expect(find.text('Offers'), findsOneWidget);

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Open drawer again
      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      // Tap Returns & Exchanges
      await tester.tap(find.text('Returns & Exchanges'));
      await tester.pumpAndSettle();

      // Verify Returns & Exchanges view is opened
      expect(find.byType(ReturnsExchangesView), findsOneWidget);
      expect(find.text('NEW RETURN / EXCHANGE'), findsOneWidget);
    });
  });
}

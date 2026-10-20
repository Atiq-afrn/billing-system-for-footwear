import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ayesha_footwear/models/bill.dart';
import 'package:ayesha_footwear/models/bill_item.dart';
import 'package:ayesha_footwear/models/customer.dart';
import 'package:ayesha_footwear/models/loyalty_models.dart';
import 'package:ayesha_footwear/models/product.dart';
import 'package:ayesha_footwear/models/return_models.dart';
import 'package:ayesha_footwear/repositories/shop_repository.dart';
import 'package:ayesha_footwear/services/bill_pdf_service.dart';
import 'package:ayesha_footwear/services/excel_export_service.dart';
import 'package:ayesha_footwear/services/whatsapp_service.dart';
import 'package:ayesha_footwear/view_models/shop_view_model.dart';
import 'package:ayesha_footwear/views/pdf_preview_view.dart';
import 'package:ayesha_footwear/views/returns_exchanges_view.dart';

class _FakeShopRepo implements ShopRepository {
  List<Product> products = [
    const Product(id: 'P1', name: 'Shoes', category: 'Formal', stock: 10, price: 1500, sizes: ['9'], colors: ['Black']),
  ];
  List<Customer> customers = [];
  List<Bill> bills = [];
  List<ReturnRecord> returns = [];
  List<StockMovement> stockMovements = [];
  LoyaltyProgramConfig loyaltyConfig = const LoyaltyProgramConfig();
  Map<String, Map<String, dynamic>> loyaltyData = {};
  List<Offer> offers = [];
  List<OfferTracking> offerTracking = [];

  @override
  Future<List<Product>> fetchProducts() async => products;
  @override
  Future<List<Customer>> fetchCustomers() async => customers;
  @override
  Future<List<Bill>> fetchBills() async => bills;
  @override
  Future<Bill> saveBill(dynamic draft) async => bills.first;
  @override
  Future<Product> saveProduct(dynamic draft) async => products.first;
  @override
  Future<void> deleteProduct(String productId) async {
    products.removeWhere((p) => p.id == productId);
  }
  @override
  Future<void> updateProductStock(String productId, int newStock) async {}
  @override
  Future<List<String>> fetchCategories() async => ['Formal'];
  @override
  Future<void> addCategory(String name) async {}
  @override
  Future<void> deleteCategory(String name) async {}
  @override
  Future<LoyaltyProgramConfig> fetchLoyaltyConfig() async => loyaltyConfig;
  @override
  Future<void> saveLoyaltyConfig(LoyaltyProgramConfig config) async { loyaltyConfig = config; }
  @override
  Future<Map<String, Map<String, dynamic>>> fetchAllCustomerLoyaltyData() async => loyaltyData;
  @override
  Future<void> updateCustomerLoyalty({required String customerId, int? points, int? pointsRedeemed, bool? marketingConsent, String? notes}) async {}
  @override
  Future<List<Offer>> fetchOffers() async => offers;
  @override
  Future<void> saveOffer(Offer offer) async {}
  @override
  Future<void> deleteOffer(String offerId) async {}
  @override
  Future<List<OfferTracking>> fetchOfferTracking() async => offerTracking;
  @override
  Future<void> recordOfferSent(OfferTracking tracking) async {}
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
  Future<void> updateReturnStatus({required String returnId, required ReturnStatus status, String? rejectionReason, String? approvedBy}) async {}
  @override
  Future<List<StockMovement>> fetchStockMovements() async => stockMovements;
  @override
  Future<void> recordStockMovement(StockMovement movement) async { stockMovements.add(movement); }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic PDF Company Generation Tests', () {
    test('BillPdfService generates PDF bytes with dynamic company name, address, mobile and upi', () async {
      final service = BillPdfService();
      final bill = Bill(
        id: 'BILL-1001',
        customerId: 'cust-1',
        productId: 'prod-1',
        customer: 'John Doe',
        mobile: '9876543210',
        item: 'Leather Boots',
        size: '9',
        color: 'Brown',
        qty: 2,
        price: 1500,
        discount: 100,
        total: 2900,
        payMode: 'UPI',
        note: 'Customer request',
        time: DateTime.now(),
        items: [
          BillItem(productId: 'prod-1', productName: 'Leather Boots', size: '9', color: 'Brown', qty: 2, price: 1500),
        ],
      );

      final bytes = await service.buildBillPdf(
        bill,
        companyName: 'Metro Footwear Studio',
        address: '123 Market Street, Mumbai',
        mobile: '9123456780',
        upiId: 'metrofootwear@okhdfcbank',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    testWidgets('PdfPreviewView renders dynamic company name in title', (tester) async {
      final bill = Bill(
        id: 'BILL-1002',
        customerId: 'cust-2',
        productId: 'prod-2',
        customer: 'Alice',
        mobile: '9988776655',
        item: 'Sports Shoes',
        size: '8',
        color: 'Blue',
        qty: 1,
        price: 1200,
        discount: 0,
        total: 1200,
        payMode: 'Cash',
        note: '',
        time: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PdfPreviewView(
            bill: bill,
            companyName: 'Apex Footwear Hub',
            companyAddress: '45 Commercial Lane',
            companyMobile: '9876500000',
            upiId: 'apexfootwear@okaxis',
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Apex Footwear Hub'), findsOneWidget);
      expect(find.text('Tax Invoice • Bill #BILL-1002'), findsOneWidget);
    });
  });

  group('Responsive Non-Overflowing Return & Exchange View Tests', () {
    testWidgets('ReturnsExchangesView adapts to narrow phone dimensions without overflow', (tester) async {
      // Simulate narrow mobile screen (320 x 600)
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = _FakeShopRepo();
      fakeRepo.returns = [
        ReturnRecord(
          id: 'RET-1771234567890',
          billId: 'BILL-1771234567890',
          customerId: 'cust-1',
          customerName: 'A Very Long Customer Name That Might Overflow',
          mobile: '9876543210',
          type: ReturnType.exchange,
          status: ReturnStatus.pendingApproval,
          returnReason: 'Wrong Size',
          productCondition: ProductCondition.sellable,
          returnedTotalAmount: 1500,
          exchangeTotalAmount: 1800,
          netAmount: 300,
          refundMethod: 'Cash',
          refundStatus: 'Pending',
          transactionRef: 'UPI-UTR-999888777666',
          approvedBy: 'Admin',
          createdAt: DateTime.now(),
          items: [
            ReturnItem(
              productId: 'prod-1',
              productName: 'Long Product Name Formal Shoe',
              size: '10',
              color: 'Black',
              qty: 1,
              unitPrice: 1500,
              reason: 'Wrong Size',
              condition: ProductCondition.sellable,
            ),
          ],
          exchangeItems: [
            ExchangeItem(
              productId: 'prod-2',
              productName: 'Replacement Casual Loafers',
              size: '9',
              color: 'Brown',
              qty: 1,
              unitPrice: 1800,
            ),
          ],
        ),
      ];

      final vm = ShopViewModel(fakeRepo, ExcelExportService(), WhatsAppService());
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: ReturnsExchangesView(viewModel: vm),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the screen and its contents render without throwing Flutter exceptions
      expect(find.text('Return & Exchange Management'), findsOneWidget);
      expect(find.text('Returns & Exchanges'), findsOneWidget);
      expect(find.text('RET-1771234567890'), findsOneWidget);
      expect(find.text('View Receipt'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      // Verify no RenderFlex overflow error occurred in tester
      expect(tester.takeException(), isNull);
    });
  });
}

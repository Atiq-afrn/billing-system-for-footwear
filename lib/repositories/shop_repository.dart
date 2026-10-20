import '../models/bill.dart';
import '../models/bill_draft.dart';
import '../models/customer.dart';
import '../models/loyalty_models.dart';
import '../models/product.dart';
import '../models/product_draft.dart';
import '../models/return_models.dart';

abstract class ShopRepository {
  Future<List<Product>> fetchProducts();
  Future<List<Customer>> fetchCustomers();
  Future<List<Bill>> fetchBills();
  Future<Bill> saveBill(BillDraft draft);
  Future<Product> saveProduct(ProductDraft draft);
  Future<void> deleteProduct(String productId);
  Future<void> updateProductStock(String productId, int newStock);
  Future<List<String>> fetchCategories();
  Future<void> addCategory(String name);
  Future<void> deleteCategory(String name);

  // Loyalty & Offers
  Future<LoyaltyProgramConfig> fetchLoyaltyConfig();
  Future<void> saveLoyaltyConfig(LoyaltyProgramConfig config);
  Future<Map<String, Map<String, dynamic>>> fetchAllCustomerLoyaltyData();
  Future<void> updateCustomerLoyalty({
    required String customerId,
    int? points,
    int? pointsRedeemed,
    bool? marketingConsent,
    String? notes,
  });
  Future<List<Offer>> fetchOffers();
  Future<void> saveOffer(Offer offer);
  Future<void> deleteOffer(String offerId);
  Future<List<OfferTracking>> fetchOfferTracking();
  Future<void> recordOfferSent(OfferTracking tracking);
  Future<void> recordOfferRedeemed({
    required String trackingId,
    required String billId,
    required int salesAmount,
  });

  // Returns & Exchanges
  Future<List<ReturnRecord>> fetchReturns();
  Future<ReturnRecord> createReturnOrExchange(ReturnRecord returnRecord);
  Future<void> updateReturnStatus({
    required String returnId,
    required ReturnStatus status,
    required String approvedBy,
    String? rejectionReason,
  });
  Future<List<StockMovement>> fetchStockMovements();
  Future<void> recordStockMovement(StockMovement movement);
}

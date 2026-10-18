import '../services/database_service.dart';
import 'sqlite_shop_repository.dart';

class LocalShopRepository extends SqliteShopRepository {
  LocalShopRepository() : super(DatabaseService());
}

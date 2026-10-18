import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'repositories/sqlite_shop_repository.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/database_service.dart';
import 'services/excel_export_service.dart';
import 'view_models/shop_view_model.dart';
import 'views/auth_view.dart';
import 'views/company_selection_view.dart';
import 'views/shop_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.initialize();
  CloudSyncService.instance.initialize();
  runApp(const AyeshaFootwearApp());
  // Explicitly enable offline persistence (default is true on Android)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}

class AyeshaFootwearApp extends StatefulWidget {
  const AyeshaFootwearApp({super.key});

  @override
  State<AyeshaFootwearApp> createState() => _AyeshaFootwearAppState();
}

class _AyeshaFootwearAppState extends State<AyeshaFootwearApp> {
  late final ShopViewModel viewModel;

  @override
  void initState() {
    super.initState();
    final databaseService = DatabaseService();
    final repository = SqliteShopRepository(
      databaseService,
      () => AuthService.instance.activeCompanyId,
    );
    viewModel = ShopViewModel(
      repository,
      ExcelExportService(),
      null,
      databaseService,
    )..initialize();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, AuthService.instance]),
      builder: (context, _) {
        final authService = AuthService.instance;
        final isAuth = authService.isAuthenticated;
        final hasActiveCompany = authService.activeCompany != null;

        Widget homeWidget;
        if (!isAuth) {
          homeWidget = AuthView(
            onAuthSuccess: () async {
              await viewModel.onUserAuthenticated();
            },
          );
        } else if (!hasActiveCompany) {
          homeWidget = CompanySelectionView(
            viewModel: viewModel,
            onCompanySelected: (company) async {
              await viewModel.switchCompany(company);
            },
          );
        } else {
          homeWidget = ShopShell(viewModel: viewModel);
        }

        return MaterialApp(
          title: viewModel.companyName,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: homeWidget,
        );
      },
    );
  }
}

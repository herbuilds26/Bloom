import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'features/auth/auth_service.dart';
import 'features/partner/partner_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  await PartnerSyncService.instance.init();
  runApp(const ProviderScope(child: BloomApp()));
}

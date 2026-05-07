import 'package:flutter/material.dart';

import 'app/linked_arabic_app.dart';
import 'data/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initializeIfConfigured();
  runApp(const LinkedArabicApp());
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'services/db_service.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local database
  await DBService.instance.database;

  // Preload Google Fonts
  await GoogleFonts.pendingFonts([GoogleFonts.poppins()]);

  runApp(const ProviderScope(child: MyApp()));
}

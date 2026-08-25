import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:daypulse/core/database/app_database.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return await AppDatabase.instance;
});
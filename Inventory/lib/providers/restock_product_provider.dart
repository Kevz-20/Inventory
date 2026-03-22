import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

final restockProductProvider = StateProvider<ProductModel?>((ref) => null);

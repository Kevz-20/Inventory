
import '../models/payable_model.dart';
import '../services/db_service.dart';

class PayableRepository {
  Future<List<Payable>> getAllPayables() async {
    final db = await DBService.instance.database;

    final result = await db.query(
      'payable',
      orderBy: 'due_date ASC', // optional: sort by due date
    );

    return result.map((e) => Payable.fromMap(e)).toList();
  }
}

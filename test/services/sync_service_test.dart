import 'package:dswd_slp/services/db_service.dart';
import 'package:dswd_slp/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await _resetDatabase();
  });

  group('SyncService queue behavior', () {
    test('enqueueUpsert deduplicates pending jobs for same org and local uuid', () async {
      await _configureOrg('org-a');
      final service = SyncService.instance;

      await service.enqueueUpsert(entityType: 'product', localUuid: 'prod-1');
      await service.enqueueUpsert(
        entityType: 'product',
        localUuid: 'prod-1',
        payload: {'source': 'retry'},
      );

      final db = await DBService.instance.database;
      final rows = await db.query('sync_queue');

      expect(rows, hasLength(1));
      expect(rows.first['entity_type'], 'product');
      expect(rows.first['local_uuid'], 'prod-1');
      expect(rows.first['status'], 'pending');
    });

    test('pending jobs and summary are scoped to selected organization', () async {
      final service = SyncService.instance;

      await _configureOrg('org-a');
      await service.enqueueUpsert(entityType: 'product', localUuid: 'prod-a');

      await _configureOrg('org-b');
      await service.enqueueUpsert(entityType: 'product', localUuid: 'prod-b');

      await _configureOrg('org-a');
      final orgAPending = await service.getPendingJobs();
      final orgASummary = await service.getQueueSummary();

      await _configureOrg('org-b');
      final orgBPending = await service.getPendingJobs();
      final orgBSummary = await service.getQueueSummary();

      expect(orgAPending, hasLength(1));
      expect(orgAPending.first['local_uuid'], 'prod-a');
      expect(orgASummary.pendingCount, 1);

      expect(orgBPending, hasLength(1));
      expect(orgBPending.first['local_uuid'], 'prod-b');
      expect(orgBSummary.pendingCount, 1);
    });

    test('resyncRecord maps diagnostics entities to queue entity types', () async {
      await _configureOrg('org-a');
      final service = SyncService.instance;

      await service.resyncRecord(entityType: 'receivables', localUuid: 'rcv-1');
      await service.resyncRecord(entityType: 'payments', localUuid: 'pay-1');

      final db = await DBService.instance.database;
      final rows = await db.query(
        'sync_queue',
        columns: ['entity_type', 'local_uuid'],
        orderBy: 'id ASC',
      );

      expect(rows, hasLength(2));
      expect(rows[0]['entity_type'], 'sales');
      expect(rows[0]['local_uuid'], 'rcv-1');
      expect(rows[1]['entity_type'], 'customer_payment');
      expect(rows[1]['local_uuid'], 'pay-1');
    });

    test('requeueJobWithForceOverwrite resets failed job and adds payload flag', () async {
      await _configureOrg('org-a');
      final db = await DBService.instance.database;
      final service = SyncService.instance;
      final now = DateTime.now().toIso8601String();

      final jobId = await db.insert('sync_queue', {
        'organization_id': 'org-a',
        'entity_type': 'product',
        'operation': 'upsert',
        'local_uuid': 'prod-1',
        'payload': '{"existing":true}',
        'status': 'failed',
        'retry_count': 2,
        'last_error': 'conflict',
        'scheduled_at': now,
        'created_at': now,
        'updated_at': now,
      });

      await service.requeueJobWithForceOverwrite(jobId);

      final rows = await db.query(
        'sync_queue',
        columns: ['status', 'last_error', 'payload', 'organization_id'],
        where: 'id = ?',
        whereArgs: [jobId],
        limit: 1,
      );

      expect(rows, hasLength(1));
      expect(rows.first['status'], 'pending');
      expect(rows.first['last_error'], isNull);
      expect(rows.first['organization_id'], 'org-a');
      final payload = rows.first['payload'] as String?;
      expect(payload, isNotNull);
      expect(payload, contains('"force_overwrite":true'));
      expect(payload, contains('"existing":true'));
    });

    test('retryFailedJobs only updates failed jobs for selected organization', () async {
      await _configureOrg('org-a');
      final db = await DBService.instance.database;
      final service = SyncService.instance;
      final now = DateTime.now().toIso8601String();

      await db.insert('sync_queue', {
        'organization_id': 'org-a',
        'entity_type': 'product',
        'operation': 'upsert',
        'local_uuid': 'prod-a',
        'status': 'failed',
        'retry_count': 1,
        'last_error': 'error-a',
        'scheduled_at': now,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('sync_queue', {
        'organization_id': 'org-b',
        'entity_type': 'product',
        'operation': 'upsert',
        'local_uuid': 'prod-b',
        'status': 'failed',
        'retry_count': 1,
        'last_error': 'error-b',
        'scheduled_at': now,
        'created_at': now,
        'updated_at': now,
      });

      await service.retryFailedJobs();

      final rows = await db.query(
        'sync_queue',
        columns: ['organization_id', 'status', 'last_error'],
        orderBy: 'organization_id ASC',
      );

      expect(rows, hasLength(2));
      expect(rows[0]['organization_id'], 'org-a');
      expect(rows[0]['status'], 'pending');
      expect(rows[0]['last_error'], isNull);
      expect(rows[1]['organization_id'], 'org-b');
      expect(rows[1]['status'], 'failed');
      expect(rows[1]['last_error'], 'error-b');
    });
  });

  group('SyncService diagnostics', () {
    test('record diagnostics include latest failed queue metadata', () async {
      await _configureOrg('org-a');
      final db = await DBService.instance.database;
      final service = SyncService.instance;
      final now = DateTime.now().toIso8601String();

      await db.insert('product', {
        'name': 'Test Product',
        'category': 'Pagkaon',
        'purchase_price': 10.0,
        'selling_price': 15.0,
        'quantity': 5,
        'created_at': now,
        'updated_at': now,
        'local_uuid': 'prod-1',
        'sync_status': 'pending_upload',
      });

      await db.insert('sync_queue', {
        'organization_id': 'org-a',
        'entity_type': 'product',
        'operation': 'upsert',
        'local_uuid': 'prod-1',
        'status': 'failed',
        'retry_count': 3,
        'last_error': 'backend conflict detected',
        'scheduled_at': now,
        'created_at': now,
        'updated_at': now,
      });

      final diagnostics = await service.getRecordDiagnostics('product');
      final product = diagnostics.firstWhere((row) => row.localUuid == 'prod-1');

      expect(product.title, 'Test Product');
      expect(product.syncStatus, 'pending_upload');
      expect(product.lastQueueError, 'backend conflict detected');
      expect(product.retryCount, 3);
      expect(product.queueUpdatedAt, now);
    });

    test('record diagnostics only show failed queue metadata from selected organization', () async {
      await _configureOrg('org-a');
      final db = await DBService.instance.database;
      final service = SyncService.instance;
      final now = DateTime.now().toIso8601String();

      await db.insert('product', {
        'name': 'Scoped Product',
        'category': 'Pagkaon',
        'purchase_price': 10.0,
        'selling_price': 15.0,
        'quantity': 5,
        'created_at': now,
        'updated_at': now,
        'local_uuid': 'prod-scope',
        'sync_status': 'pending_upload',
      });

      await db.insert('sync_queue', {
        'organization_id': 'org-b',
        'entity_type': 'product',
        'operation': 'upsert',
        'local_uuid': 'prod-scope',
        'status': 'failed',
        'retry_count': 9,
        'last_error': 'wrong-org error',
        'scheduled_at': now,
        'created_at': now,
        'updated_at': now,
      });

      final diagnostics = await service.getRecordDiagnostics('product');
      final product =
          diagnostics.firstWhere((row) => row.localUuid == 'prod-scope');

      expect(product.lastQueueError, isNull);
      expect(product.retryCount, 0);
      expect(product.queueUpdatedAt, isNull);
    });

    test('sales diagnostics include latest failed sales queue metadata', () async {
      await _configureOrg('org-a');
      final db = await DBService.instance.database;
      final service = SyncService.instance;
      final now = DateTime.now().toIso8601String();

      await db.insert('sales', {
        'sale_type': 'cash',
        'total': 250,
        'created_at': now,
        'local_uuid': 'sale-1',
        'sync_status': 'pending_upload',
      });

      await db.insert('sync_queue', {
        'organization_id': 'org-a',
        'entity_type': 'sales',
        'operation': 'upsert',
        'local_uuid': 'sale-1',
        'status': 'failed',
        'retry_count': 2,
        'last_error': 'sale sync failed',
        'scheduled_at': now,
        'created_at': now,
        'updated_at': now,
      });

      final diagnostics = await service.getRecordDiagnostics('sales');
      final sale = diagnostics.firstWhere((row) => row.localUuid == 'sale-1');

      expect(sale.title, 'cash sale');
      expect(sale.subtitle, 'Total: 250');
      expect(sale.lastQueueError, 'sale sync failed');
      expect(sale.retryCount, 2);
    });

    test('receivables diagnostics use failed sales queue metadata', () async {
      await _configureOrg('org-a');
      final db = await DBService.instance.database;
      final service = SyncService.instance;
      final now = DateTime.now().toIso8601String();

      await db.insert('sales_credit', {
        'amount': 400.0,
        'credit_date': now,
        'due_date': '2026-03-30',
        'created_at': now,
        'local_uuid': 'rcv-1',
        'sync_status': 'pending_upload',
      });

      await db.insert('sync_queue', {
        'organization_id': 'org-a',
        'entity_type': 'sales',
        'operation': 'upsert',
        'local_uuid': 'rcv-1',
        'status': 'failed',
        'retry_count': 1,
        'last_error': 'receivable sale sync failed',
        'scheduled_at': now,
        'created_at': now,
        'updated_at': now,
      });

      final diagnostics = await service.getRecordDiagnostics('receivables');
      final receivable =
          diagnostics.firstWhere((row) => row.localUuid == 'rcv-1');

      expect(receivable.title, 'Receivable');
      expect(receivable.subtitle, contains('Amount: 400.0'));
      expect(receivable.subtitle, contains('Due: 2026-03-30'));
      expect(receivable.lastQueueError, 'receivable sale sync failed');
      expect(receivable.retryCount, 1);
    });

    test('payments diagnostics use failed customer payment queue metadata', () async {
      await _configureOrg('org-a');
      final db = await DBService.instance.database;
      final service = SyncService.instance;
      final now = DateTime.now().toIso8601String();

      final customerId = await db.insert('customer', {
        'first_name': 'Test',
        'middle_name': null,
        'last_name': 'Customer',
        'phone_number': '09171234567',
        'municipality': 'Sample Town',
        'barangay': 'Barangay 1',
        'landmark': 'Near plaza',
        'credit_limit': 1000.0,
        'available_credit': 1000.0,
        'created_at': now,
        'updated_at': now,
        'local_uuid': 'cust-pay-1',
        'sync_status': 'synced',
      });

      await db.insert('customer_payment', {
        'customer_id': customerId,
        'amount': 175.0,
        'paid_at': now,
        'local_uuid': 'pay-1',
        'sync_status': 'pending_upload',
      });

      await db.insert('sync_queue', {
        'organization_id': 'org-a',
        'entity_type': 'customer_payment',
        'operation': 'upsert',
        'local_uuid': 'pay-1',
        'status': 'failed',
        'retry_count': 4,
        'last_error': 'payment sync failed',
        'scheduled_at': now,
        'created_at': now,
        'updated_at': now,
      });

      final diagnostics = await service.getRecordDiagnostics('payments');
      final payment = diagnostics.firstWhere((row) => row.localUuid == 'pay-1');

      expect(payment.title, 'Customer payment');
      expect(payment.subtitle, 'Amount: 175.0');
      expect(payment.lastQueueError, 'payment sync failed');
      expect(payment.retryCount, 4);
    });
  });
}

Future<void> _configureOrg(String organizationId) async {
  SharedPreferences.setMockInitialValues({
    'selectedOrganizationId': organizationId,
  });
}

Future<void> _resetDatabase() async {
  await DBService.instance.close();
  final path = join(await getDatabasesPath(), 'app_data.db');
  await deleteDatabase(path);
}

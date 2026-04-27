import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _serviceId  = 'service_mu1vij8';
  static const _templateId = 'template_bw3oaa8';
  static const _publicKey  = 'p4eMgeo7OeM3hAybI';
  static const _url = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Sends a product edit/delete alert to the PDO. Fire-and-forget — never throws.
  Future<void> sendProductAlert({
    required String action,        // 'Edited' or 'Deleted'
    required String productName,
    required String memberName,
    required String association,
    String changes = '',           // e.g. "Price: ₱250.00 → ₱280.00"
  }) async {
    try {
      final now = DateFormat('MMMM d, yyyy \'at\' h:mm a').format(DateTime.now());
      final body = jsonEncode({
        'service_id':  _serviceId,
        'template_id': _templateId,
        'user_id':     _publicKey,
        'template_params': {
          'action':       action,
          'product_name': productName,
          'changes':      changes.isEmpty ? '—' : changes,
          'member_name':  memberName,
          'association':  association,
          'time':         now,
        },
      });

      print('[notify] Sending alert → action=$action product="$productName"');
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      print('[notify] EmailJS status: ${response.statusCode}');
      print('[notify] EmailJS body:   ${response.body}');
    } catch (e) {
      print('[notify] EXCEPTION: $e');
    }
  }

  /// Builds a human-readable diff string from two product maps.
  static String buildChanges(
    Map<String, dynamic>? oldMap,
    Map<String, dynamic>? newMap,
  ) {
    if (oldMap == null || newMap == null) return '';

    final fields = <String, String Function(dynamic)>{
      'name':          (v) => '$v',
      'selling_price': (v) => '₱${double.tryParse('$v')?.toStringAsFixed(2) ?? v}',
      'quantity':      (v) => '$v',
      'description':   (v) => '$v',
      'category':      (v) => '$v',
      'unit':          (v) => '$v',
    };

    final labels = {
      'name':          'Name',
      'selling_price': 'Price',
      'quantity':      'Stock',
      'description':   'Description',
      'category':      'Category',
      'unit':          'Unit',
    };

    final parts = <String>[];
    for (final key in fields.keys) {
      final ov = '${oldMap[key] ?? ''}';
      final nv = '${newMap[key] ?? ''}';
      if (ov != nv) {
        final fmt = fields[key]!;
        parts.add('${labels[key]}: ${fmt(ov.isEmpty ? '—' : ov)} → ${fmt(nv.isEmpty ? '—' : nv)}');
      }
    }
    return parts.join('\n');
  }
}

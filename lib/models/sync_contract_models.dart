class BackendSyncRequest {
  BackendSyncRequest({
    required this.generatedAt,
    required this.tables,
    required this.counts,
    required this.totalRecords,
  });

  final String generatedAt;
  final Map<String, List<Map<String, dynamic>>> tables;
  final Map<String, int> counts;
  final int totalRecords;

  factory BackendSyncRequest.fromPayload(Map<String, dynamic> payload) {
    final tableMap = Map<String, dynamic>.from(
      payload['tables'] as Map? ?? const {},
    );

    return BackendSyncRequest(
      generatedAt: payload['generated_at']?.toString() ?? '',
      tables: tableMap.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList(),
        ),
      ),
      counts: Map<String, int>.from(payload['counts'] as Map? ?? const {}),
      totalRecords: (payload['total_records'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt,
      'tables': tables,
      'counts': counts,
      'total_records': totalRecords,
    };
  }
}

class BackendSyncResponse {
  BackendSyncResponse({
    required this.success,
    required this.message,
    required this.syncedIdsByTable,
    required this.serverIdsByTable,
    required this.syncedAt,
  });

  final bool success;
  final String message;
  final Map<String, List<int>> syncedIdsByTable;
  final Map<String, Map<int, String>> serverIdsByTable;
  final String? syncedAt;

  factory BackendSyncResponse.fromJson(Map<String, dynamic> json) {
    final syncedIdsRaw = Map<String, dynamic>.from(
      json['synced_ids_by_table'] as Map? ?? const {},
    );
    final serverIdsRaw = Map<String, dynamic>.from(
      json['server_ids_by_table'] as Map? ?? const {},
    );

    return BackendSyncResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      syncedIdsByTable: syncedIdsRaw.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((id) => (id as num).toInt())
              .toList(),
        ),
      ),
      serverIdsByTable: serverIdsRaw.map(
        (table, value) => MapEntry(
          table,
          Map<String, dynamic>.from(value as Map).map(
            (id, serverId) => MapEntry(
              int.parse(id.toString()),
              serverId.toString(),
            ),
          ),
        ),
      ),
      syncedAt: json['synced_at']?.toString(),
    );
  }
}

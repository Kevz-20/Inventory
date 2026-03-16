import 'dart:convert';
import 'dart:io';

import '../models/sync_contract_models.dart';

class BackendSyncService {
  BackendSyncService({
    required this.baseUrl,
    this.authToken,
    this.clientFactory,
  });

  final String baseUrl;
  final String? authToken;
  final HttpClient Function()? clientFactory;

  Uri get _syncUri => Uri.parse(
        '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}/api/mobile/sync/upload',
      );

  Future<BackendSyncResponse> uploadPayload(
    BackendSyncRequest request,
  ) async {
    final client = clientFactory?.call() ?? HttpClient();

    try {
      final httpRequest = await client.postUrl(_syncUri);
      httpRequest.headers.contentType = ContentType.json;
      if (authToken != null && authToken!.trim().isNotEmpty) {
        httpRequest.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${authToken!.trim()}',
        );
      }

      httpRequest.write(jsonEncode(request.toJson()));
      final httpResponse = await httpRequest.close();
      final responseBody = await utf8.decodeStream(httpResponse);

      if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
        throw HttpException(
          'Sync upload failed with status ${httpResponse.statusCode}: $responseBody',
          uri: _syncUri,
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid sync response format');
      }

      final response = BackendSyncResponse.fromJson(decoded);
      if (!response.success) {
        throw StateError(
          response.message.isEmpty ? 'Backend sync returned failure' : response.message,
        );
      }

      return response;
    } finally {
      client.close(force: true);
    }
  }
}

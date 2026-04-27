import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class LlmService {
  /// Fetch the list of model IDs from [baseUrl]/v1/models.
  Future<List<String>> fetchModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    final uri = Uri.parse('${_normalizeBase(baseUrl)}/v1/models');
    final res = await http.get(uri, headers: _headers(apiKey));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    final ids = data
        .map((e) => (e as Map<String, dynamic>)['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList()
      ..sort();
    return ids;
  }

  /// Stream chat completion delta tokens via SSE.
  Stream<String> chatStream({
    required String baseUrl,
    required String apiKey,
    required String modelId,
    required List<Map<String, String>> messages,
  }) async* {
    final uri =
        Uri.parse('${_normalizeBase(baseUrl)}/v1/chat/completions');
    final client = http.Client();
    try {
      final request = http.Request('POST', uri);
      request.headers.addAll({
        ..._headers(apiKey),
        HttpHeaders.contentTypeHeader: 'application/json',
      });
      request.body = jsonEncode({
        'model': modelId,
        'messages': messages,
        'stream': true,
      });

      final streamed = await client.send(request);
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        throw Exception('HTTP ${streamed.statusCode}: $body');
      }

      await for (final line in streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload == '[DONE]') return;
        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;
          final delta =
              (choices[0] as Map<String, dynamic>)['delta'] as Map<String, dynamic>?;
          final content = delta?['content'];
          if (content is String && content.isNotEmpty) yield content;
        } catch (_) {
          // malformed chunk — skip
        }
      }
    } finally {
      client.close();
    }
  }

  String _normalizeBase(String url) {
    final trimmed = url.trim();
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  Map<String, String> _headers(String apiKey) => {
        HttpHeaders.authorizationHeader: 'Bearer $apiKey',
        HttpHeaders.acceptHeader: 'application/json',
      };
}

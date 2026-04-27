class LlmConfig {
  final int? id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final int createdAt;

  const LlmConfig({
    this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.createdAt,
  });

  factory LlmConfig.fromMap(Map<String, dynamic> m) => LlmConfig(
        id: m['id'] as int?,
        name: m['name'] as String,
        baseUrl: m['base_url'] as String,
        apiKey: m['api_key'] as String,
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'base_url': baseUrl,
        'api_key': apiKey,
        'created_at': createdAt,
      };
}

class ChatSession {
  final int? id;
  final int configId;
  final String modelId;
  final String title;
  final int createdAt;
  final int updatedAt;

  const ChatSession({
    this.id,
    required this.configId,
    required this.modelId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromMap(Map<String, dynamic> m) => ChatSession(
        id: m['id'] as int?,
        configId: m['config_id'] as int,
        modelId: m['model_id'] as String,
        title: m['title'] as String,
        createdAt: m['created_at'] as int,
        updatedAt: m['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'config_id': configId,
        'model_id': modelId,
        'title': title,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class ChatMessage {
  final int? id;
  final int sessionId;
  final String role; // 'user' | 'assistant'
  final String content;
  final int createdAt;

  const ChatMessage({
    this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as int?,
        sessionId: m['session_id'] as int,
        role: m['role'] as String,
        content: m['content'] as String,
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'role': role,
        'content': content,
        'created_at': createdAt,
      };
}

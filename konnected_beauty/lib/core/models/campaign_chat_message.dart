enum CampaignMessageType {
  message,
  configuration,
}

enum CampaignMessageSenderType {
  salon,
  influencer,
}

class CampaignChatMessageItem {
  final String id;
  final String content;
  final CampaignMessageType type;
  final String senderType;
  final String? senderId;
  final String senderName;
  final Object? senderProfilePicture;
  final DateTime createdAt;

  const CampaignChatMessageItem({
    required this.id,
    required this.content,
    required this.type,
    required this.senderType,
    required this.senderId,
    required this.senderName,
    required this.senderProfilePicture,
    required this.createdAt,
  });

  static CampaignMessageType _parseType(dynamic v) {
    final s = v?.toString().toLowerCase();
    if (s == CampaignMessageType.configuration.name) {
      return CampaignMessageType.configuration;
    }
    return CampaignMessageType.message;
  }

  static DateTime _parseCreatedAt(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static Object? _parseProfilePicture(dynamic v) {
    if (v == null) return null;
    if (v is String || v is List) return v;
    return v.toString();
  }

  static CampaignChatMessageItem? tryParse(dynamic data) {
    if (data is! Map) return null;
    final m = Map<String, dynamic>.from(data);
    final id = m['id']?.toString();
    final content = m['content']?.toString();
    if (id == null || id.isEmpty || content == null) return null;

    return CampaignChatMessageItem(
      id: id,
      content: content,
      type: _parseType(m['type']),
      senderType: m['senderType']?.toString() ?? '',
      senderId: m['senderId']?.toString(),
      senderName: m['senderName']?.toString() ?? '',
      senderProfilePicture: _parseProfilePicture(m['senderProfilePicture']),
      createdAt: _parseCreatedAt(m['createdAt']),
    );
  }
}

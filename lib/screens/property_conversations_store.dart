import 'package:real_estate/models/property.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PropertyConversation {
  final Property property;
  String lastMessage;
  String lastTime;
  List<Map<String, dynamic>> messages;

  PropertyConversation({
    required this.property,
    required this.lastMessage,
    required this.lastTime,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'property': property.toJson(),
    'lastMessage': lastMessage,
    'lastTime': lastTime,
    'messages': messages,
  };

  static PropertyConversation fromJson(Map<String, dynamic> json) {
    return PropertyConversation(
      property: Property.fromJson(json['property']),
      lastMessage: json['lastMessage'] ?? '',
      lastTime: json['lastTime'] ?? '',
      messages:
          (json['messages'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
  }
}

class PropertyConversationsStore {
  static final List<PropertyConversation> _conversations = [];
  static bool _loaded = false;

  static Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('property_conversations') ?? [];
    _conversations.clear();
    _conversations.addAll(
      data.map((e) => PropertyConversation.fromJson(jsonDecode(e))),
    );
    _loaded = true;
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _conversations.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList('property_conversations', data);
  }

  static Future<List<PropertyConversation>> getConversations() async {
    await _load();
    return List.unmodifiable(_conversations);
  }

  static List<PropertyConversation> get conversations => _conversations;

  static Future<void> upsertConversation(
    Property property,
    String lastMessage, {
    Map<String, dynamic>? newMessage,
  }) async {
    await _load();
    final now = DateTime.now();
    final lastTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final idx = _conversations.indexWhere((c) => c.property.id == property.id);
    if (idx >= 0) {
      _conversations[idx].lastMessage = lastMessage;
      _conversations[idx].lastTime = lastTime;
      if (newMessage != null) {
        _conversations[idx].messages.add(newMessage);
      }
    } else {
      _conversations.insert(
        0,
        PropertyConversation(
          property: property,
          lastMessage: lastMessage,
          lastTime: lastTime,
          messages: newMessage != null ? [newMessage] : [],
        ),
      );
    }
    await _save();
  }

  static Future<List<Map<String, dynamic>>> getMessagesForProperty(
    String propertyId,
  ) async {
    await _load();
    final idx = _conversations.indexWhere((c) => c.property.id == propertyId);
    if (idx >= 0) {
      return List<Map<String, dynamic>>.from(_conversations[idx].messages);
    }
    return [];
  }
}

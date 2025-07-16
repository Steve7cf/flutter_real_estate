import 'package:flutter/material.dart';
import 'package:real_estate/models/property.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:real_estate/screens/property_conversations_store.dart';

class PropertyChatScreen extends StatefulWidget {
  final Property property;
  const PropertyChatScreen({super.key, required this.property});

  @override
  State<PropertyChatScreen> createState() => _PropertyChatScreenState();
}

class _PropertyChatScreenState extends State<PropertyChatScreen> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final loaded = await PropertyConversationsStore.getMessagesForProperty(
      widget.property.id,
    );
    setState(() {
      messages.clear();
      messages.addAll(loaded);
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final msg = {
      'text': text,
      'isSent': true,
      'time': TimeOfDay.now().format(context),
    };
    setState(() {
      messages.add(msg);
    });
    // Update conversation store with the new message
    PropertyConversationsStore.upsertConversation(
      widget.property,
      text,
      newMessage: msg,
    );
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: property.images.isNotEmpty
                  ? (property.images.first.startsWith('/') ||
                            property.images.first.startsWith('file://'))
                        ? Image.file(
                            File(property.images.first),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: property.images.first,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                  : Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 28),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    property.location,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message['isSent']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Column(
                      crossAxisAlignment: message['isSent']
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: message['isSent']
                                ? theme.primaryColor
                                : theme.cardColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: message['isSent']
                                  ? const Radius.circular(20)
                                  : const Radius.circular(4),
                              bottomRight: message['isSent']
                                  ? const Radius.circular(4)
                                  : const Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            message['text'],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: message['isSent']
                                  ? Colors.white
                                  : theme.textTheme.bodyLarge?.color,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            message['time'],
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

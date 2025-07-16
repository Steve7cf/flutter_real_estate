import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:real_estate/screens/property_conversations_store.dart';
import 'package:real_estate/screens/property_chat_screen.dart';
import 'dart:io';

void main() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Professional Messenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff35573B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        primaryColor: const Color(0xff35573B),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF212529),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: const MessageScreen(),
    );
  }
}

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  // No longer used: final List<Map<String, dynamic>> conversations = [];
  // No longer used: final Map<int, List<Map<String, dynamic>>> conversationMessages = {};

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  List<PropertyConversation> get filteredConversations {
    final allConvs = PropertyConversationsStore.conversations;
    if (searchQuery.isEmpty) return allConvs;
    return allConvs
        .where(
          (conv) =>
              conv.property.title.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              conv.lastMessage.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: _buildConversationsList()),
    );
  }

  Widget _buildConversationsList() {
    final theme = Theme.of(context);
    final List<PropertyConversation> conversations = filteredConversations;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Messages',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: GoogleFonts.inter(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6C757D),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Conversations List
        Expanded(
          child: conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a chat from any property to see it here.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final property = conv.property;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                PropertyChatScreen(property: property),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(4),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: property.images.isNotEmpty
                                    ? (property.images.first.startsWith('/') ||
                                              property.images.first.startsWith(
                                                'file://',
                                              ))
                                          ? Image.file(
                                              File(property.images.first),
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              property.images.first,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            )
                                    : Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          size: 28,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      property.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      conv.lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                conv.lastTime,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ChatView extends StatefulWidget {
  final String name;
  final String avatar;
  final String status;
  final List<Map<String, dynamic>> messages;
  final VoidCallback onBack;

  const ChatView({
    super.key,
    required this.name,
    required this.avatar,
    required this.status,
    required this.messages,
    required this.onBack,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.messages.add({
        'text': text,
        'isSent': true,
        'time': TimeOfDay.now().format(context),
      });
    });
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xff35573B),
                child: Text(
                  widget.avatar,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      widget.status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              final message = widget.messages[index];
              return ChatBubble(
                message: message['text'],
                isSent: message['isSent'],
                time: message['time'],
              );
            },
          ),
        ),
        // Message Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 16,
                      ),
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
                decoration: const BoxDecoration(
                  color: Color(0xff35573B),
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
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSent;
  final String time;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSent,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isSent
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSent
                    ? const Color(0xff35573B)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isSent
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isSent
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
                message,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isSent
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

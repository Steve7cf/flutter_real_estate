import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
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
  final List<Map<String, dynamic>> conversations = const [
    {
      'id': 1,
      'name': 'Mikel Johnson',
      'message': 'Hi, are you available for the meeting?',
      'time': '15:58',
      'unread': 2,
      'avatar': 'MJ',
      'isOnline': true,
      'lastSeen': 'Online'
    },
    {
      'id': 2,
      'name': 'Jane Doe',
      'message': 'I have sent you the quarterly reports',
      'time': '14:30',
      'unread': 0,
      'avatar': 'JD',
      'isOnline': false,
      'lastSeen': '2 hours ago'
    },
    {
      'id': 3,
      'name': 'John Smith',
      'message': 'Please review the new project proposal',
      'time': '13:15',
      'unread': 1,
      'avatar': 'JS',
      'isOnline': true,
      'lastSeen': 'Online'
    },
    {
      'id': 4,
      'name': 'Sarah Wilson',
      'message': 'Thanks for the update!',
      'time': '12:45',
      'unread': 0,
      'avatar': 'SW',
      'isOnline': false,
      'lastSeen': '1 day ago'
    },
  ];

  final List<Map<String, dynamic>> sampleMessages = const [
    {'id': 1, 'text': 'Hi, are you available for the meeting?', 'time': '15:58', 'isSent': false},
    {'id': 2, 'text': 'Yes, I am! What time works for you?', 'time': '15:59', 'isSent': true},
    {'id': 3, 'text': 'How about 3 PM today? We can discuss the project requirements.', 'time': '16:00', 'isSent': false},
    {'id': 4, 'text': 'Perfect! Ill prepare the presentation slides.', 'time': '16:01', 'isSent': true},
    {'id': 5, 'text': 'Great! Looking forward to it. See you at 3 PM.', 'time': '16:02', 'isSent': false},
  ];

  int? selectedConversationId;
  String? selectedName;
  String? selectedAvatar;
  String? selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  void selectConversation(Map<String, dynamic> conversation) {
    setState(() {
      selectedConversationId = conversation['id'];
      selectedName = conversation['name'];
      selectedAvatar = conversation['avatar'];
      selectedStatus = conversation['lastSeen'];
    });
  }

  List<Map<String, dynamic>> get filteredConversations {
    if (searchQuery.isEmpty) return conversations;
    return conversations.where((conv) =>
        conv['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
        conv['message'].toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: selectedConversationId == null
            ? _buildConversationsList()
            : ChatView(
                name: selectedName!,
                avatar: selectedAvatar!,
                status: selectedStatus!,
                messages: sampleMessages,
                onBack: () => setState(() => selectedConversationId = null),
              ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                      color: const Color(0xFF212529),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF8F9FA),
                          foregroundColor: const Color(0xFF6C757D),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xff35573B),
                          foregroundColor: Colors.white,
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
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF6C757D),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6C757D)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Conversations List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: filteredConversations.length,
            itemBuilder: (context, index) {
              final conversation = filteredConversations[index];
              return _buildConversationTile(conversation);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => selectConversation(conversation),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xff35573B),
                      child: Text(
                        conversation['avatar'],
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (conversation['isOnline'])
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xff35573B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            conversation['name'],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF212529),
                            ),
                          ),
                          Text(
                            conversation['time'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6C757D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation['message'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: conversation['unread'] > 0 
                                    ? const Color(0xFF495057)
                                    : const Color(0xFF6C757D),
                                fontWeight: conversation['unread'] > 0 
                                    ? FontWeight.w500 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (conversation['unread'] > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xff35573B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation['unread'].toString(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  backgroundColor: const Color(0xFFF8F9FA),
                  foregroundColor: const Color(0xFF212529),
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
                        color: const Color(0xFF212529),
                      ),
                    ),
                    Text(
                      widget.status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6C757D),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF8F9FA),
                  foregroundColor: const Color(0xFF212529),
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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF6C757D),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      // Handle send message
                      _messageController.clear();
                    }
                  },
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
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSent ? const Color(0xff35573B) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isSent ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isSent ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isSent ? Colors.white : const Color(0xFF212529),
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
                  color: const Color(0xFF6C757D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'models/cooker.dart';
import 'theme.dart';
import 'services/firestore_message_service.dart';

class CookerMessagesPage extends StatefulWidget {
  final Cooker cooker;
  final String? conversationId;

  const CookerMessagesPage({super.key, required this.cooker, this.conversationId});

  @override
  State<CookerMessagesPage> createState() => _CookerMessagesPageState();
}

class _CookerMessagesPageState extends State<CookerMessagesPage> {
  String? _conversationId;
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  Future<void> _initConversation() async {
    try {
      if (widget.conversationId != null) {
        _conversationId = widget.conversationId;
      } else {
        // Get or create conversation with this cooker
        _conversationId = await FirestoreMessageService.getOrCreateConversation(widget.cooker.id);
      }
      
      // Mark messages as read
      if (_conversationId != null) {
        await FirestoreMessageService.markAsRead(_conversationId!);
      }
    } catch (e) {
      print('Error initializing conversation: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _conversationId == null) return;
    
    _controller.clear();
    
    try {
      await FirestoreMessageService.sendMessage(_conversationId!, text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إرسال الرسالة: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  ImageProvider? _avatarProvider(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    return AssetImage(url);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 1,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage: _avatarProvider(widget.cooker.avatarUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cooker.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'متصل',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha((0.9 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _conversationId == null
                        ? const Center(child: Text('خطأ في تحميل المحادثة'))
                        : StreamBuilder<List<MessageModel>>(
                            stream: FirestoreMessageService.getMessagesStream(_conversationId!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final messages = snapshot.data ?? [];
                              
                              if (messages.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text('ابدأ المحادثة مع ${widget.cooker.name}', 
                                           style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                );
                              }

                              // Auto scroll when new messages arrive
                              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                              return ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final m = messages[index];
                                  final isMe = m.isMe(FirestoreMessageService.currentUserId);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: _MessageBubble(
                                      text: m.text,
                                      isMe: isMe,
                                      time: m.timestamp ?? DateTime.now(),
                                      showAvatar: !isMe,
                                      avatarUrl: widget.cooker.avatarUrl,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),

                  // Input area
                  SafeArea(
                    minimum: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withAlpha((0.03 * 255).round()),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    textAlign: TextAlign.right,
                                    decoration: const InputDecoration(
                                      hintText: 'اكتب رسالة...',
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onSubmitted: _sendMessage,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _sendMessage(_controller.text),
                                  icon: const Icon(Icons.send, color: Color(0xFF2E6BF6)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool showAvatar;
  final String avatarUrl;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
    this.showAvatar = false,
    this.avatarUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? const Color(0xFF2E6BF6) : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMe ? 14 : 6),
      topRight: Radius.circular(isMe ? 6 : 14),
      bottomLeft: const Radius.circular(14),
      bottomRight: const Radius.circular(14),
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          if (showAvatar)
            CircleAvatar(
              backgroundImage: avatarUrl.startsWith('http')
                  ? NetworkImage(avatarUrl)
                  : AssetImage(avatarUrl) as ImageProvider,
              radius: 16,
              backgroundColor: Colors.grey[200],
              onBackgroundImageError: (_, __) {},
            ),
          const SizedBox(width: 8),
        ],

        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              boxShadow: isMe
                  ? [
                      BoxShadow(
                        color: Colors.black12.withAlpha((0.08 * 255).round()),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black12.withAlpha((0.03 * 255).round()),
                        blurRadius: 2,
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(color: textColor, height: 1.4),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(time),
                      style: TextStyle(
                        color: textColor.withAlpha((0.7 * 255).round()),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (isMe) const SizedBox(width: 8),
      ],
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

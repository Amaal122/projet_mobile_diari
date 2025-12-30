import 'dart:async';

import 'package:flutter/material.dart';

class CookerMessagesPage extends StatefulWidget {
  final String cookerName;
  final String cookerAvatarUrl;

  const CookerMessagesPage({
    super.key,
    required this.cookerName,
    required this.cookerAvatarUrl,
  });

  @override
  State<CookerMessagesPage> createState() => _CookerMessagesPageState();
}

class _CookerMessagesPageState extends State<CookerMessagesPage> {
  final List<_Message> _messages = [
    _Message(
      text: 'مرحباً! شنو تحب تطلب اليوم؟',
      isMe: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    _Message(
      text: 'نحب نطلب كسكسي اليوم، شنو الأسعار؟',
      isMe: true,
      time: DateTime.now().subtract(const Duration(minutes: 4, seconds: 30)),
    ),
    _Message(
      text: 'الكسكسي  للواحد 15.50TND، تحب نحصلك خدمة التوصيل؟',
      isMe: false,
      time: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final msg = _Message(text: text.trim(), isMe: true, time: DateTime.now());
    setState(() => _messages.add(msg));
    _controller.clear();
    _scrollToBottom();

    // optional auto-reply simulation from cooker
    Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _Message(
            text: 'جميل! نتحضرك الطلب وتوصلك رسالة تأكيد قريباً.',
            isMe: false,
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFEA8F78),
          elevation: 1,
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.cookerAvatarUrl),
                radius: 18,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cookerName,
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
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  final showAvatar = !m.isMe;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _MessageBubble(
                      text: m.text,
                      isMe: m.isMe,
                      time: m.time,
                      showAvatar: showAvatar,
                      avatarUrl: widget.cookerAvatarUrl,
                    ),
                  );
                },
              ),
            ),

            // Input area
            SafeArea(
              minimum: const EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 8,
                top: 8,
              ),
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
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: _sendMessage,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _sendMessage(_controller.text),
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF2E6BF6),
                            ),
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

class _Message {
  final String text;
  final bool isMe;
  final DateTime time;

  _Message({required this.text, required this.isMe, required this.time});
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
              backgroundImage: NetworkImage(avatarUrl),
              radius: 16,
              backgroundColor: Colors.grey[200],
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

import 'package:flutter/material.dart';
import 'models/cooker.dart';
import 'cooker_messages.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  static final List<_Conversation> _conversations = [
    _Conversation(
      name: 'فاطمة الغربي',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
      lastMessage: 'الكسكسي جاهز للتوصيل اليوم الساعة 1',
      time: DateTime.now().subtract(const Duration(minutes: 12)),
      unread: 2,
    ),
    _Conversation(
      name: 'سارة محمد',
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
      lastMessage: 'باهي، نبعثلك العنوان متاع الدار',
      time: DateTime.now().subtract(const Duration(hours: 3, minutes: 5)),
      unread: 0,
    ),
    _Conversation(
      name: 'محمد علي',
      avatarUrl:
          'https://images.unsplash.com/photo-1545996124-1b1c9b8c5f0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
      lastMessage: 'شكراً على الوجبة، كانت لذيذة',
      time: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      unread: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الرسائل'),
          backgroundColor: const Color(0xFFEA8F78),
        ),
        body: ListView.separated(
          itemCount: _conversations.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final c = _conversations[index];
            return _ConversationTile(
              conversation: c,
              onTap: () {
                final cooker = Cooker(
                  id: c.name,
                  name: c.name,
                  avatarUrl: c.avatarUrl,
                  location: '',
                  rating: 0.0,
                  bio: '',
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CookerMessagesPage(cooker: cooker),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Conversation {
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final DateTime time;
  final int unread;

  _Conversation({
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
  });
}

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'الآن';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(conversation.avatarUrl),
        backgroundColor: Colors.grey[200],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            _formatTime(conversation.time),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E6BF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${conversation.unread}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'models/cooker.dart';
import 'cooker_messages.dart';
import 'theme.dart';
import 'services/firestore_message_service.dart';

class MessagesPage extends StatefulWidget {
  final bool showNavBar;
  const MessagesPage({super.key, this.showNavBar = true});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الرسائل'),
          backgroundColor: AppColors.primary,
        ),
        body: StreamBuilder<List<ConversationModel>>(
          stream: FirestoreMessageService.getConversationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('خطأ في تحميل المحادثات', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              );
            }

            final conversations = snapshot.data ?? [];

            if (conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('لا توجد محادثات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'ابدأ محادثة مع طباخ من صفحة الطباخين',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return _ConversationTile(
                  conversation: conv,
                  onTap: () {
                    final cooker = Cooker(
                      id: conv.otherUserId,
                      name: conv.otherUserName,
                      avatarUrl: conv.otherUserImage,
                      location: '',
                      rating: 0.0,
                      bio: '',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CookerMessagesPage(
                          cooker: cooker,
                          conversationId: conv.id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
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
        backgroundColor: Colors.grey[200],
        backgroundImage: conversation.otherUserImage.isNotEmpty
            ? NetworkImage(conversation.otherUserImage)
            : null,
        child: conversation.otherUserImage.isEmpty
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.otherUserName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            _formatTime(conversation.lastMessageTime),
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
                conversation.lastMessage.isNotEmpty 
                    ? conversation.lastMessage 
                    : 'ابدأ المحادثة...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: conversation.lastMessage.isEmpty ? Colors.grey : null,
                ),
              ),
            ),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${conversation.unreadCount}',
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

import 'package:supabase_flutter/supabase_flutter.dart';

class MonetizationChatService {
  MonetizationChatService._();
  static final MonetizationChatService instance = MonetizationChatService._();
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchMessages(String conversationId) async {
    final data = await _client
        .from('chat_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final senderId = _client.auth.currentUser?.id;
    if (senderId == null) throw StateError('يجب تسجيل الدخول لإرسال رسالة');
    await _client.from('chat_messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    });
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('chat_messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId);
  }

  RealtimeChannel subscribeToConversationMessages({
    required String conversationId,
    required void Function(Map<String, dynamic> message) onNewMessage,
  }) {
    final channel = _client
        .channel('chat_messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onNewMessage(payload.newRecord);
          },
        );
    channel.subscribe();
    return channel;
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final uid = ref.watch(activeUserIdProvider);
  return ChatRepository(FirebaseFirestore.instance, uid);
});

final chatHistoryStreamProvider = StreamProvider<List<ChatSession>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatHistory();
});

class ChatRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  ChatRepository(this._firestore, this._uid);

  CollectionReference get _chatCollection {
    if (_uid.isEmpty) {
      throw Exception('User is not authenticated');
    }
    return _firestore.collection('users').doc(_uid).collection('chat_history');
  }

  Stream<List<ChatSession>> getChatHistory() {
    if (_uid.isEmpty) return Stream.value([]);
    
    return _chatCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> saveChatSession(ChatSession session) async {
    if (_uid.isEmpty) return;
    
    await _chatCollection.doc(session.id).set(
          session.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteChatSession(String sessionId) async {
    if (_uid.isEmpty) return;
    
    await _chatCollection.doc(sessionId).delete();
  }

  Future<void> clearAllHistory() async {
    if (_uid.isEmpty) return;
    
    final snapshot = await _chatCollection.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

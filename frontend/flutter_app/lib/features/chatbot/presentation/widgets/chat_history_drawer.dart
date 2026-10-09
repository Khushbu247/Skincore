import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';

class ChatHistoryDrawer extends ConsumerWidget {
  final String currentSessionId;
  final Function(ChatSession) onSessionSelected;
  final VoidCallback onNewChat;

  const ChatHistoryDrawer({
    super.key,
    required this.currentSessionId,
    required this.onSessionSelected,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(chatHistoryStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chat History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.purple),
                  onPressed: () {
                    Navigator.pop(context);
                    onNewChat();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: historyAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(
                    child: Text(
                      'No saved chats.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isCurrent = session.id == currentSessionId;
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.muted),
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? AppColors.purple : (isDark ? Colors.white : AppColors.ink),
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(session.updatedAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      selected: isCurrent,
                      selectedTileColor: AppColors.purple.withValues(alpha: 0.1),
                      onTap: () {
                        Navigator.pop(context);
                        onSessionSelected(session);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.muted),
                        onPressed: () => _confirmDelete(context, ref, session.id),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.delete_forever, color: AppColors.rose),
              label: const Text('Clear All History', style: TextStyle(color: AppColors.rose)),
              onPressed: () => _confirmClearAll(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('chat_delete_title')),
        content: Text(AppLocalizations.of(context).translate('chat_delete_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).translate('common_cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(chatRepositoryProvider).deleteChatSession(id);
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('chat_clear_history_title')),
        content: Text(AppLocalizations.of(context).translate('chat_clear_history_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).translate('common_cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(chatRepositoryProvider).clearAllHistory();
      onNewChat();
      if (context.mounted) Navigator.pop(context);
    }
  }
}

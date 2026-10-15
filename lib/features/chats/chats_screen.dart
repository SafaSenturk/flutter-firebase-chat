import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final me = ref.watch(meProvider).value;
    final chats = ref.watch(chatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: PulseTheme.brandGradient),
              child: const Icon(Icons.forum_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(l.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.findPeople,
            onPressed: () => context.push('/people'),
            icon: const Icon(Icons.person_search_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: Semantics(
                label: l.profile,
                button: true,
                child: Avatar(user: me, size: 38, showOnline: false),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/people'),
        icon: const Icon(Icons.edit_rounded),
        label: Text(l.newChat, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: chats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(onRetry: () => ref.invalidate(chatsProvider)),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.chat_bubble_rounded,
                title: l.noChatsTitle,
                body: l.noChatsBody,
                action: FilledButton.icon(
                  onPressed: () => context.push('/people'),
                  icon: const Icon(Icons.person_search_rounded),
                  label: Text(l.findPeople),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: list.length,
                itemBuilder: (context, i) => _ChatTile(chat: list[i], me: me?.uid ?? ''),
              ),
      ),
    );
  }
}

class _ChatTile extends ConsumerStatefulWidget {
  const _ChatTile({required this.chat, required this.me});

  final Chat chat;
  final String me;

  @override
  ConsumerState<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends ConsumerState<_ChatTile> {
  Timer? _typingTimer;

  @override
  void didUpdateWidget(covariant _ChatTile old) {
    super.didUpdateWidget(old);
    _scheduleTypingExpiry();
  }

  @override
  void initState() {
    super.initState();
    _scheduleTypingExpiry();
  }

  /// "typing…" must disappear on its own even if no new snapshot arrives.
  void _scheduleTypingExpiry() {
    _typingTimer?.cancel();
    final other = widget.chat.otherMember(widget.me);
    if (widget.chat.isTyping(other)) {
      _typingTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final chat = widget.chat;
    final otherId = chat.otherMember(widget.me);
    final other = ref.watch(userProvider(otherId)).value;
    final unread = chat.unreadFor(widget.me);
    final last = chat.lastMessage;
    final typing = chat.isTyping(otherId);

    final String preview;
    if (last == null) {
      preview = '';
    } else if (last.deleted) {
      preview = l.messageDeleted;
    } else {
      preview = last.senderId == widget.me ? '${l.you}: ${last.text}' : last.text;
    }

    return InkWell(
      onTap: () => context.push('/chat/$otherId'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Hero(tag: 'avatar-$otherId', child: Avatar(user: other, size: 56)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          other?.name ?? '…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        context.chatTime(chat.updatedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: unread > 0 ? PulseTheme.accent : context.pulse.inkSoft,
                          fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.centerLeft,
                            children: [...previous, ?current],
                          ),
                          child: Text(
                            typing ? l.typing : preview,
                            key: ValueKey(typing),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: typing ? PulseTheme.accent : context.pulse.inkSoft,
                              fontStyle: last?.deleted == true && !typing ? FontStyle.italic : null,
                              fontWeight: typing || unread > 0 ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: PulseTheme.brandGradient,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
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
    );
  }
}

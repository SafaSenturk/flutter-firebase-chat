import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/chat_repository.dart';
import '../../data/models.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.otherUid});

  final String otherUid;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _focus = FocusNode();
  late final String _me = ref.read(uidProvider)!;
  late final String _chatId = Chat.idFor(_me, widget.otherUid);
  // Kept as fields because `ref` can't be used in dispose().
  late final ChatRepository _repo;
  late final OpenChat _openChat;
  Timer? _typingIdle;
  DateTime _lastTypingPing = DateTime(2000);
  Message? _editing;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(chatRepositoryProvider);
    _openChat = ref.read(openChatProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => _openChat.set(_chatId));
    _input.addListener(_onTextChanged);
    // Re-evaluates the "typing…" state, which expires by time.
    _tick = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _typingIdle?.cancel();
    _stopTyping();
    // Defer: providers can't be modified while the widget tree is being torn down.
    final openChat = _openChat;
    Future.microtask(() => openChat.set(null));
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _openChat.set(state == AppLifecycleState.resumed ? _chatId : null);
    if (state == AppLifecycleState.resumed) _markRead();
  }

  bool get _chatExists => ref.read(chatProvider(_chatId)).value != null;

  void _onTextChanged() {
    setState(() {});
    if (!_chatExists || _input.text.isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastTypingPing).inSeconds >= 3) {
      _lastTypingPing = now;
      _repo.setTyping(_chatId, _me, typing: true).ignore();
    }
    _typingIdle?.cancel();
    _typingIdle = Timer(const Duration(seconds: 4), _stopTyping);
  }

  void _stopTyping() {
    if (_lastTypingPing.year == 2000) return;
    _lastTypingPing = DateTime(2000);
    _repo.setTyping(_chatId, _me, typing: false).ignore();
  }

  Future<void> _markRead() async {
    final chat = ref.read(chatProvider(_chatId)).value;
    final messages = ref.read(messagesProvider(_chatId)).value ?? const [];
    final hasUnread = messages.any((m) => m.senderId != _me && m.readAt == null && !m.pending);
    if (chat == null || (chat.unreadFor(_me) == 0 && !hasUnread)) return;
    try {
      await ref.read(chatRepositoryProvider).markRead(_chatId, _me);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final repo = ref.read(chatRepositoryProvider);
    final editing = _editing;
    _input.clear();
    setState(() => _editing = null);
    unawaited(HapticFeedback.selectionClick());
    _typingIdle?.cancel();
    _lastTypingPing = DateTime(2000);
    try {
      if (editing != null) {
        await repo.editMessage(_chatId, editing.id, text);
      } else {
        await repo.sendMessage(from: _me, to: widget.otherUid, text: text);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.errorUnknown)));
      }
    }
  }

  Future<void> _showActions(Message m, bool isLatest) async {
    final l = context.l;
    final mine = m.senderId == _me;
    unawaited(HapticFeedback.mediumImpact());
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final e in const ['❤️', '😂', '👍', '😮', '😢', '🔥'])
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        ref.read(chatRepositoryProvider).react(_chatId, m, _me, e).ignore();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: m.reactions[_me] == e ? PulseTheme.accent.withValues(alpha: .2) : null,
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(l.copy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: m.text));
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
              },
            ),
            if (mine) ...[
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(l.edit),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _editing = m);
                  _input.text = m.text;
                  _focus.requestFocus();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: context.scheme.error),
                title: Text(l.delete, style: TextStyle(color: context.scheme.error)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(l.deleteMessageTitle),
                      content: Text(l.deleteMessageBody),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(l.delete, style: TextStyle(color: context.scheme.error)),
                        ),
                      ],
                    ),
                  );
                  if (ok ?? false) {
                    ref.read(chatRepositoryProvider).deleteMessage(_chatId, m.id, isLatest: isLatest).ignore();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final other = ref.watch(userProvider(widget.otherUid)).value;
    final chat = ref.watch(chatProvider(_chatId)).value;
    final messages = ref.watch(messagesProvider(_chatId));
    final otherTyping = chat?.isTyping(widget.otherUid) ?? false;

    // Mark incoming messages as read while this screen is open.
    ref.listen(messagesProvider(_chatId), (_, next) {
      if (next.hasValue) _markRead();
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(tag: 'avatar-${widget.otherUid}', child: Avatar(user: other, size: 42)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      otherTyping ? l.typing : (other == null ? '' : context.presence(other)),
                      key: ValueKey(otherTyping),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: otherTyping || (other?.online ?? false) ? PulseTheme.accent : context.pulse.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(onRetry: () => ref.invalidate(messagesProvider(_chatId))),
              data: (list) => list.isEmpty && !otherTyping
                  ? _Hello(name: other?.name ?? '')
                  : _MessageList(
                      messages: list,
                      me: _me,
                      showTyping: otherTyping,
                      onLongPress: _showActions,
                    ),
            ),
          ),
          if (_editing != null)
            Container(
              color: PulseTheme.accent.withValues(alpha: .1),
              padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, size: 18, color: PulseTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.editing, style: const TextStyle(fontWeight: FontWeight.w700))),
                  IconButton(
                    onPressed: () {
                      setState(() => _editing = null);
                      _input.clear();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          _Composer(controller: _input, focus: _focus, onSend: _send),
        ],
      ),
    );
  }
}

class _Hello extends StatelessWidget {
  const _Hello({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, t, child) => Transform.scale(scale: .6 + .4 * t, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(context.l.sayHello(name), style: TextStyle(color: context.pulse.inkSoft, fontSize: 16)),
            ],
          ),
        ),
      );
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.me,
    required this.showTyping,
    required this.onLongPress,
  });

  /// Newest first.
  final List<Message> messages;
  final String me;
  final bool showTyping;
  final void Function(Message, bool isLatest) onLongPress;

  static bool _sameDay(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final offset = showTyping ? 1 : 0;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: messages.length + offset,
      itemBuilder: (context, index) {
        if (showTyping && index == 0) return const _TypingBubble();
        final i = index - offset;
        final m = messages[i];
        final older = i + 1 < messages.length ? messages[i + 1] : null;
        final newer = i > 0 ? messages[i - 1] : null;
        final mine = m.senderId == me;
        // Bubbles from the same person in a row are grouped visually.
        final firstInGroup = older == null || older.senderId != m.senderId || !_sameDay(older.sentAt, m.sentAt);
        final lastInGroup = newer == null || newer.senderId != m.senderId;
        final showDate = older == null || !_sameDay(older.sentAt, m.sentAt ?? DateTime.now());

        return Column(
          children: [
            if (showDate) _DateChip(date: m.sentAt ?? DateTime.now()),
            _Bubble(
              key: ValueKey(m.id),
              message: m,
              mine: mine,
              firstInGroup: firstInGroup,
              lastInGroup: lastInGroup,
              onLongPress: m.deleted ? null : () => onLongPress(m, i == 0),
            ),
          ],
        );
      },
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: context.pulse.muted, borderRadius: BorderRadius.circular(12)),
          child: Text(
            context.dayLabel(date),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.pulse.inkSoft),
          ),
        ),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.mine,
    required this.firstInGroup,
    required this.lastInGroup,
    this.onLongPress,
  });

  final Message message;
  final bool mine;
  final bool firstInGroup;
  final bool lastInGroup;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final m = message;
    const r = Radius.circular(20);
    const small = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: mine || firstInGroup ? r : small,
      bottomLeft: mine || lastInGroup ? r : small,
      topRight: !mine || firstInGroup ? r : small,
      bottomRight: !mine || lastInGroup ? r : small,
    );
    final textColor = mine ? Colors.white : context.scheme.onSurface;
    final meta = (mine ? Colors.white : context.pulse.inkSoft).withValues(alpha: .75);
    final time = m.sentAt == null ? '' : DateFormat.Hm(context.lang).format(m.sentAt!);
    final reactions = m.reactions.values.toList();

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .76),
        padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
        decoration: BoxDecoration(
          gradient: mine && !m.deleted ? PulseTheme.brandGradient : null,
          color: mine ? (m.deleted ? context.pulse.muted : null) : context.pulse.bubbleOther,
          borderRadius: radius,
          boxShadow: mine || m.deleted
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          children: [
            Text(
              m.deleted ? context.l.messageDeleted : m.text,
              style: TextStyle(
                color: m.deleted ? context.pulse.inkSoft : textColor,
                fontSize: 16,
                height: 1.3,
                fontStyle: m.deleted ? FontStyle.italic : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.edited && !m.deleted)
                    Text('${context.l.edited} · ', style: TextStyle(fontSize: 11, color: meta)),
                  Text(time, style: TextStyle(fontSize: 11, color: m.deleted ? context.pulse.inkSoft : meta)),
                  if (mine && !m.deleted) ...[
                    const SizedBox(width: 3),
                    Icon(
                      m.pending
                          ? Icons.schedule_rounded
                          : m.readAt != null
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                      size: 15,
                      color: m.readAt != null ? const Color(0xFFB9FFF2) : meta,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      // Only freshly sent messages slide in; history appears instantly.
      tween: Tween(begin: m.pending || _isFresh(m) ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(mine ? 30 * (1 - t) : -30 * (1 - t), 0), child: child),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: firstInGroup ? 8 : 2, bottom: reactions.isEmpty ? 0 : 14),
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              bubble,
              if (reactions.isNotEmpty)
                Positioned(
                  bottom: -16,
                  right: mine ? 10 : null,
                  left: mine ? null : 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.pulse.border),
                    ),
                    child: Text(reactions.toSet().join(' ') + (reactions.length > 1 ? ' ${reactions.length}' : ''),
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isFresh(Message m) =>
      m.sentAt != null && DateTime.now().difference(m.sentAt!).inSeconds.abs() < 3;
}

/// Three bouncing dots shown while the other person types.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: context.pulse.bubbleOther, borderRadius: BorderRadius.circular(20)),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Builder(builder: (context) {
                    final t = ((_c.value - i * .15) % 1);
                    final lift = t < .4 ? (t < .2 ? t / .2 : (.4 - t) / .2) : 0.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      transform: Matrix4.translationValues(0, -5 * lift, 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PulseTheme.accent.withValues(alpha: .45 + .55 * lift),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      );
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.focus, required this.onSend});

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final canSend = controller.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: context.l.messageHint,
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: PulseTheme.accent, width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: canSend ? 1 : .85,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: canSend ? 1 : .5,
                duration: const Duration(milliseconds: 200),
                child: Material(
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: const BoxDecoration(gradient: PulseTheme.brandGradient),
                    child: InkWell(
                      onTap: canSend ? onSend : null,
                      child: const SizedBox.square(
                        dimension: 50,
                        child: Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

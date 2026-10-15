import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Every registered user, searchable by name; tapping one opens the chat.
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final people = ref.watch(peopleProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.people)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              autofocus: false,
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () => ref.read(peopleSearchProvider.notifier).set(v));
              },
              decoration: InputDecoration(hintText: l.searchPeople, prefixIcon: const Icon(Icons.search_rounded)),
            ),
          ),
          Expanded(
            child: people.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(onRetry: () => ref.invalidate(peopleProvider)),
              data: (list) => list.isEmpty
                  ? EmptyState(icon: Icons.person_off_rounded, title: l.noPeople, body: '')
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final u = list[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Hero(tag: 'avatar-${u.uid}', child: Avatar(user: u, size: 50)),
                          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          subtitle: Text(
                            u.about.isNotEmpty ? u.about : context.presence(u),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: u.online ? context.pulse.online : context.pulse.inkSoft),
                          ),
                          trailing: const Icon(Icons.chat_bubble_outline_rounded, color: PulseTheme.accent),
                          onTap: () => context.pushReplacement('/chat/${u.uid}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_state.dart';
import 'package:collab_tasks/features/calls/ui/utils/call_history_formatter.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CallHistoryScreen extends StatelessWidget {
  final String title;
  final String currentUserId;
  final String? groupId;
  final String? opponentId;

  const CallHistoryScreen({
    super.key,
    required this.title,
    required this.currentUserId,
    this.groupId,
    this.opponentId,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => getIt<CallHistoryBloc>()
        ..add(
          LoadCallHistory(currentUserId: currentUserId, groupId: groupId, opponentId: opponentId),
        ),
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: BlocBuilder<CallHistoryBloc, CallHistoryState>(
          builder: (context, state) {
            if (state is CallHistoryLoading || state is CallHistoryInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CallHistoryError) {
              return Center(child: Text(l.callHistoryLoadError));
            }
            final calls = (state as CallHistoryLoaded).calls;
            if (calls.isEmpty) return Center(child: Text(l.callHistoryEmpty));
            return ListView.separated(
              itemCount: calls.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) => _CallHistoryTile(
                call: calls[index],
                currentUserId: currentUserId,
                locale: Localizations.localeOf(context).toLanguageTag(),
                l: l,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  final Call call;
  final String currentUserId;
  final String locale;
  final AppLocalizations l;

  const _CallHistoryTile({
    required this.call,
    required this.currentUserId,
    required this.locale,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final missed = call.isMissedFor(currentUserId);
    final outgoing = call.isOutgoingFor(currentUserId);
    final icon = missed
        ? Icons.phone_missed
        : outgoing
        ? Icons.call_made
        : Icons.call_received;
    final color = outgoing ? Colors.green : Theme.of(context).colorScheme.primary;
    final date = CallHistoryFormatter.date(call.createdAt, locale);
    final time = CallHistoryFormatter.time(call.createdAt, locale);
    final duration = CallHistoryFormatter.duration(call);
    final kind = call.type.name == 'video' ? l.callHistoryVideo : l.callHistoryAudio;
    final description = missed
        ? l.callHistoryMissed(kind)
        : outgoing
        ? l.callHistoryOutgoing(kind)
        : l.callHistoryIncoming(kind);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(description),
      subtitle: Text('$date · $time'),
      trailing: Text(duration ?? l.callHistoryNoDuration),
    );
  }
}

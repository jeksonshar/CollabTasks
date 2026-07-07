import 'dart:async';

import 'package:equatable/equatable.dart';

sealed class WorkingGroupsEvent extends Equatable {
  const WorkingGroupsEvent();

  @override
  List<Object?> get props => [];
}

class WorkingGroupsStarted extends WorkingGroupsEvent {
  const WorkingGroupsStarted();
}

class WorkingGroupsRefreshed extends WorkingGroupsEvent {
  const WorkingGroupsRefreshed([this.completer]);

  final Completer<void>? completer;

  @override
  List<Object?> get props => [completer];
}

class WorkingGroupCreated extends WorkingGroupsEvent {
  const WorkingGroupCreated({required this.title, required this.description});

  final String title;
  final String description;

  @override
  List<Object?> get props => [title, description];
}

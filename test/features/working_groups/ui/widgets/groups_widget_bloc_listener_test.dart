import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:collab_tasks/features/chats/domain/models/direct_chat_result.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/get_or_create_direct_chat_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_participants_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_tasks_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_working_groups_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/sync_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_task_details/group_task_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_task_details/group_task_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_task_details/group_task_details_state.dart';
import 'package:collab_tasks/features/working_groups/ui/widgets/groups_widget_bloc_listener.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

const _channel = MethodChannel('com.collab_tasks/groups_widget');
const _groupId = 'group-1';

class _MockWatchAuthStateUseCase extends Mock implements WatchAuthStateUseCase {}

class _MockGetWorkingGroupsUseCase extends Mock implements GetWorkingGroupsUseCase {}

class _MockGetGroupParticipantsUseCase extends Mock implements GetGroupParticipantsUseCase {}

class _MockGetGroupTasksUseCase extends Mock implements GetGroupTasksUseCase {}

class _MockSyncWorkingGroupUseCase extends Mock implements SyncWorkingGroupUseCase {}

class _MockGetOrCreateDirectChatUseCase extends Mock implements GetOrCreateDirectChatUseCase {}

class _MockGroupTaskDetailsBloc extends MockBloc<GroupTaskDetailsEvent, GroupTaskDetailsState>
    implements GroupTaskDetailsBloc {}

class _RouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<AuthUser?> authController;
  late StreamController<List<WorkingGroup>> groupsController;
  late StreamController<List<GroupParticipant>> participantsController;
  late StreamController<List<GroupTask>> tasksController;
  late _MockWatchAuthStateUseCase watchAuth;
  late _MockGetWorkingGroupsUseCase watchGroups;
  late _MockGetGroupParticipantsUseCase watchParticipants;
  late _MockGetGroupTasksUseCase watchTasks;
  late _MockSyncWorkingGroupUseCase syncGroup;
  late _MockGetOrCreateDirectChatUseCase getOrCreateChat;
  late List<MethodCall> nativeCalls;
  var participants = <GroupParticipant>[];
  var tasks = <GroupTask>[];
  var participantUseCaseCalls = 0;
  var taskUseCaseCalls = 0;

  Stream<T> replayingStream<T>(T Function() current, Stream<T> updates) {
    return Stream<T>.multi((controller) {
      controller.add(current());
      final subscription = updates.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  setUp(() async {
    await getIt.reset();
    nativeCalls = [];
    participants = [];
    tasks = [];
    participantUseCaseCalls = 0;
    taskUseCaseCalls = 0;
    authController = StreamController<AuthUser?>.broadcast(sync: true);
    groupsController = StreamController<List<WorkingGroup>>.broadcast(sync: true);
    participantsController = StreamController<List<GroupParticipant>>.broadcast(sync: true);
    tasksController = StreamController<List<GroupTask>>.broadcast(sync: true);
    watchAuth = _MockWatchAuthStateUseCase();
    watchGroups = _MockGetWorkingGroupsUseCase();
    watchParticipants = _MockGetGroupParticipantsUseCase();
    watchTasks = _MockGetGroupTasksUseCase();
    syncGroup = _MockSyncWorkingGroupUseCase();
    getOrCreateChat = _MockGetOrCreateDirectChatUseCase();

    when(() => watchAuth()).thenAnswer((_) => authController.stream);
    when(() => watchGroups()).thenAnswer((_) => groupsController.stream);
    when(() => watchParticipants(any())).thenAnswer((_) {
      participantUseCaseCalls++;
      if (participantUseCaseCalls > 1) return Stream.value(participants);
      return replayingStream(() => participants, participantsController.stream);
    });
    when(() => watchTasks(any())).thenAnswer((_) {
      taskUseCaseCalls++;
      if (taskUseCaseCalls > 1) return Stream.value(tasks);
      return replayingStream(() => tasks, tasksController.stream);
    });
    when(() => syncGroup(any())).thenAnswer((_) async {});

    getIt..registerSingleton<WatchAuthStateUseCase>(watchAuth)
    ..registerSingleton<GetWorkingGroupsUseCase>(watchGroups)
    ..registerSingleton<GetGroupParticipantsUseCase>(watchParticipants)
    ..registerSingleton<GetGroupTasksUseCase>(watchTasks)
    ..registerSingleton<SyncWorkingGroupUseCase>(syncGroup)
    ..registerSingleton<GetOrCreateDirectChatUseCase>(getOrCreateChat);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _channel,
      (call) async {
        nativeCalls.add(call);
        if (call.method == 'takeInitialGroupsWidgetNavigation') return null;
        if (call.method == 'acknowledgeGroupsWidgetNavigation') return true;
        return null;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _channel,
      null,
    );
    debugDefaultTargetPlatformOverride = null;
    await authController.close();
    await groupsController.close();
    await participantsController.close();
    await tasksController.close();
    await getIt.reset();
  });

  Future<void> sendNativeNavigation(Map<String, Object?> payload) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      _channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall('widgetNavigation', payload)),
      null,
    );
  }

  Widget buildHost({required VoidCallback onOpenGroups, NavigatorObserver? observer}) {
    return MaterialApp(
      navigatorObservers: [?observer],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru'), Locale('uk')],
      home: Scaffold(
        body: GroupsWidgetBlocListener(
          onOpenGroups: onOpenGroups,
          child: const Text('Main content'),
        ),
      ),
    );
  }

  Future<void> pumpHost(
    WidgetTester tester, {
    required VoidCallback onOpenGroups,
    NavigatorObserver? observer,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(buildHost(onOpenGroups: onOpenGroups, observer: observer));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  testWidgets('publishes stream snapshots and removes deleted groups', (tester) async {
    await pumpHost(tester, onOpenGroups: () {});
    await tester.pump();

    final group = WorkingGroup(
      id: _groupId,
      title: 'Design group',
      description: 'Project description',
      createdAt: DateTime.utc(2026),
      updatedAt: 1,
    );
    groupsController.add([group]);
    await tester.pump();

    const participant = GroupParticipant(
      id: 'group-1:user-2',
      groupId: _groupId,
      userId: 'user-2',
      name: 'Sam Member',
      updatedAt: 1,
    );
    final task = GroupTask(
      id: 'task-1',
      groupId: _groupId,
      createdAt: DateTime.utc(2026),
      title: 'Review design',
      description: '',
    );
    participants = const [participant];
    tasks = [task];
    participantsController.add(participants);
    tasksController.add(tasks);
    await tester.pump();

    final snapshots = nativeCalls
        .where((call) => call.method == 'updateGroups')
        .map((call) => call.arguments as String)
        .toList();
    expect(snapshots, isNotEmpty);
    expect(snapshots.last, contains('Design group'));
    expect(snapshots.last, contains('Sam Member'));
    expect(snapshots.last, contains('Review design'));
    verify(() => syncGroup(_groupId)).called(1);

    groupsController.add(const []);
    await tester.pump();
    await tester.pump();

    final lastSnapshot = nativeCalls.lastWhere((call) => call.method == 'updateGroups');
    expect(lastSnapshot.arguments, '[]');
    expect(participantsController.hasListener, isFalse);
    expect(tasksController.hasListener, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(groupsController.hasListener, isFalse);
    expect(authController.hasListener, isFalse);
  });

  testWidgets('routes a background tap to the working-groups callback', (tester) async {
    var openGroupsCalls = 0;
    await pumpHost(tester, onOpenGroups: () => openGroupsCalls++);
    await tester.pump();

    const navigation = {'requestId': 'request-groups', 'openGroups': true};
    await sendNativeNavigation(navigation);
    await sendNativeNavigation(navigation);
    await tester.pump();

    expect(openGroupsCalls, 1);
    expect(
      nativeCalls.where((call) => call.method == 'acknowledgeGroupsWidgetNavigation'),
      hasLength(2),
    );
  });

  testWidgets('opens a loading route while resolving a participant direct chat', (tester) async {
    final observer = _RouteObserver();
    final chatCompleter = Completer<DirectChatResult>();
    when(
      () => getOrCreateChat(groupId: _groupId, participantCompositeId: 'group-1:user-2'),
    ).thenAnswer((_) => chatCompleter.future);

    await pumpHost(tester, onOpenGroups: () {}, observer: observer);
    await tester.pump();
    await sendNativeNavigation({
      'requestId': 'request-participant',
      'participantGroupId': _groupId,
      'participantId': 'group-1:user-2',
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    verify(
      () => getOrCreateChat(groupId: _groupId, participantCompositeId: 'group-1:user-2'),
    ).called(1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(observer.pushedRoutes, hasLength(2));
    expect(
      nativeCalls.where((call) => call.method == 'acknowledgeGroupsWidgetNavigation'),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens group task details using the latest group streams', (tester) async {
    final observer = _RouteObserver();
    const participant = GroupParticipant(
      id: 'group-1:user-2',
      groupId: _groupId,
      userId: 'user-2',
      name: 'Sam Member',
      updatedAt: 1,
    );
    final task = GroupTask(
      id: 'task-1',
      groupId: _groupId,
      createdAt: DateTime.utc(2026),
      title: 'Review design',
      description: '',
    );
    participants = const [participant];
    tasks = [task];
    final detailsBloc = _MockGroupTaskDetailsBloc();
    GroupTask? openedTask;
    when(() => detailsBloc.state).thenReturn(GroupTaskDetailsState(task: task));
    when(() => detailsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => detailsBloc.close()).thenAnswer((_) async {});
    getIt.registerFactoryParam<GroupTaskDetailsBloc, GroupTask, void>((requestedTask, _) {
      openedTask = requestedTask;
      return detailsBloc;
    });

    await pumpHost(tester, onOpenGroups: () {}, observer: observer);
    await tester.pump();
    groupsController.add([
      WorkingGroup(
        id: _groupId,
        title: 'Design group',
        description: '',
        createdAt: DateTime.utc(2026),
        updatedAt: 1,
      ),
    ]);
    await tester.pump();
    await sendNativeNavigation({
      'requestId': 'request-task',
      'taskGroupId': _groupId,
      'taskId': task.id,
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    verify(() => watchParticipants(_groupId)).called(2);
    verify(() => watchTasks(_groupId)).called(2);
    expect(observer.pushedRoutes, hasLength(2));
    expect(openedTask?.id, task.id);
    expect(
      nativeCalls.where((call) => call.method == 'acknowledgeGroupsWidgetNavigation'),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });
}

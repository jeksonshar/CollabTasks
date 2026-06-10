import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/ui/dialogs/task_dialog/ui_components/task_attachment_tile.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TaskAttachmentTile shows file metadata and opens file on tile tap', (tester) async {
    var viewCount = 0;

    await tester.pumpWidget(
      buildTestApp(
        TaskAttachmentTile(
          attachment: const TaskAttachment(
            id: 'file-1',
            name: 'notes.txt',
            extension: 'txt',
            sizeBytes: 1536,
          ),
          onView: () => viewCount++,
          onDownload: () {},
          onDelete: () {},
          isLoading: false,
        ),
      ),
    );

    expect(find.text('notes.txt'), findsOneWidget);
    expect(find.text('TXT • 1.5 KB'), findsOneWidget);
    expect(find.byIcon(Icons.description), findsOneWidget);

    await tester.tap(find.text('notes.txt'));
    await tester.pump();

    expect(viewCount, 1);
  });

  testWidgets('TaskAttachmentTile exposes view, download, and delete menu actions', (tester) async {
    var viewCount = 0;
    var downloadCount = 0;
    var deleteCount = 0;

    await tester.pumpWidget(
      buildTestApp(
        TaskAttachmentTile(
          attachment: const TaskAttachment(
            id: 'file-1',
            name: 'report.pdf',
            extension: 'pdf',
            sizeBytes: 2 * 1024 * 1024,
          ),
          onView: () => viewCount++,
          onDownload: () => downloadCount++,
          onDelete: () => deleteCount++,
          isLoading: false,
        ),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(viewCount, 1);
    expect(downloadCount, 1);
    expect(deleteCount, 1);
  });

  testWidgets('TaskAttachmentTile disables menu actions while loading', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        TaskAttachmentTile(
          attachment: const TaskAttachment(
            id: 'file-1',
            name: 'remote.pdf',
            extension: 'pdf',
            sizeBytes: 2048,
          ),
          onView: () {},
          onDownload: () {},
          onDelete: () {},
          isLoading: true,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });
}

Widget buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ru'), Locale('uk')],
    home: Scaffold(body: Center(child: child)),
  );
}

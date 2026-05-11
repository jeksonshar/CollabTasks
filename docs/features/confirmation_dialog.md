# Confirmation Dialog (Deletion)

## Goal
Provide a reusable, generic confirmation dialog component powered by BLoC for handling user confirmations before destructive actions (deletion of subtasks, attachments, deadlines, etc.).

## Architecture

### BLoC: `ConfirmationDialogBloc`
Manages the state and events of the confirmation dialog.

**State:** `ConfirmationDialogState`
- `status`: `ConfirmationDialogStatus` (initial, pending, confirmed, cancelled)
- `title`: Optional dialog title
- `message`: Dialog message text
- `confirmButtonLabel`: Text for the confirm button
- `cancelButtonLabel`: Text for the cancel button

**Events:**
- `InitializeConfirmationDialog`: Initialize dialog with custom text
- `ConfirmationDialogConfirmed`: User clicked confirm button
- `ConfirmationDialogCancelled`: User clicked cancel button
- `ResetConfirmationDialog`: Clear state back to initial

### Widget: `ConfirmationDialog`
A reusable dialog widget that displays confirmation prompts.

**Parameters:**
- `onConfirm`: Callback when user confirms the action
- `onCancel`: Optional callback when user cancels
- `customTitle`, `customMessage`, `customConfirmLabel`, `customCancelLabel`: Override text from BLoC if provided

**Behavior:**
- Listens to `ConfirmationDialogBloc` state changes
- Closes dialog and executes callback on confirmation
- Supports customization at both BLoC and widget levels

## Usage Pattern

```dart
// 1. Get the BLoC from service locator
final confirmationDialogBloc = getIt<ConfirmationDialogBloc>();

// 2. Initialize with confirmation text
confirmationDialogBloc.add(
  InitializeConfirmationDialog(
    title: localization.attentionTitle,
    message: localization.confirmDeleteSubtask,
    confirmButtonLabel: localization.delete,
    cancelButtonLabel: localization.cancel,
  ),
);

// 3. Show the dialog
showDialog(
  context: context,
  builder: (dialogContext) => BlocProvider.value(
    value: confirmationDialogBloc,
    child: ConfirmationDialog(
      onConfirm: () {
        // Perform the deletion action
      },
      onCancel: () {
        confirmationDialogBloc.add(const ResetConfirmationDialog());
      },
    ),
  ),
).then((_) {
  // Reset state after dialog closes
  confirmationDialogBloc.add(const ResetConfirmationDialog());
});
```

**Note:** `const` is omitted in step 2 because the constructor parameters are runtime values from localization. Use `const` only for events without parameters or with compile-time constant values (see `ResetConfirmationDialog` in step 3).

## Implementation Details

### Files
- `lib/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_bloc.dart`: BLoC class
- `lib/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_event.dart`: Event definitions
- `lib/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_state.dart`: State definition
- `lib/ui/dialogs/confirmation_dialog.dart`: Dialog widget

### Registration
- **DI:** Registered as `factory` in `service_locator.dart` to create new instances for each use

### Integration
- Used in `TaskSubtasksSection` for subtask deletion confirmation
- Used in `TaskAttachmentsSection` for attachment deletion confirmation
- Used in `TaskDeadlineSection` for deadline deletion confirmation
- Provided via `BlocProvider` in `TaskDialog` to all child widgets

## Localization
Dialog messages are passed from parent widgets and fully localized:
- English, Russian, Ukrainian support via ARB files
- Keys: `confirmDeleteSubtask`, `confirmDeleteDeadline`, `confirmDeleteFile`

## Future Extensions
This pattern can be reused for:
- Task deletion confirmation
- Any destructive action requiring user confirmation

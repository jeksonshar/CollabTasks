import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';

mixin L10nMixin<T extends StatefulWidget> on State<T> {
  AppLocalizations get localization {
    final loc = AppLocalizations.of(context);
    assert(loc != null, 'AppLocalizations not found in context');
    return loc!;
  }
}

import 'package:flutter/cupertino.dart';

import 'app_localizations.dart';

mixin L10nMixin<T extends StatefulWidget> on State<T> {
  AppLocalizations get localization {
    final loc = AppLocalizations.of(context);
    assert(loc != null, 'AppLocalizations not found in context');
    return loc!;
  }
}

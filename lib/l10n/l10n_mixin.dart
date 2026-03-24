import 'package:flutter/cupertino.dart';

import 'app_localizations.dart';

mixin L10nMixin<T extends StatefulWidget> on State<T> {
  AppLocalizations get localization => AppLocalizations.of(context)!;
}

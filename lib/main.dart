import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/api/token_store.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // The persisted session has to be read before the first request, so the data
  // layer is built here rather than inside the widget tree.
  final TokenStore tokens = await TokenStore.create();
  final AppRepositories repositories = await AppRepositories.api(tokens: tokens);

  runApp(JobmateApp(repositories: repositories));
}

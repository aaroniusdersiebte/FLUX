import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/library_screen.dart';
import 'screens/reader_screen.dart';
import 'services/app_state.dart';
import 'theme/terminal_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: TerminalColors.background,
  ));

  final appState = AppState();
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const FluxApp(),
    ),
  );
}

class FluxApp extends StatelessWidget {
  const FluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLUX',
      debugShowCheckedModeBanner: false,
      theme: TerminalTheme.build(),
      // Register the RouteObserver so ReaderScreen gets didPopNext callbacks
      navigatorObservers: [ReaderScreen.routeObserver],
      home: const LibraryScreen(),
    );
  }
}

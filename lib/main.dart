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
    return Consumer<AppState>(
      builder: (context, state, _) {
        final colors = state.isDarkMode ? AppColors.dark : AppColors.light;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              state.isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: colors.background,
        ));
        return MaterialApp(
          title: 'FLUX',
          debugShowCheckedModeBanner: false,
          theme: TerminalTheme.build(colors),
          navigatorObservers: [ReaderScreen.routeObserver],
          home: const LibraryScreen(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'nav_key.dart';
import 'screens/library_screen.dart';
import 'screens/reader_screen.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'theme/terminal_theme.dart';
import 'widgets/tutorial_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
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
        final base = state.isDarkMode ? AppColors.dark : AppColors.light;
        final accent = state.accentColor;
        final colors = base.copyWith(
          amber: accent,
          amberDim: accent.withValues(alpha: 0x4D / 255),
          fontFamily: state.fontFamily,
        );
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
          navigatorKey: appNavigatorKey,
          navigatorObservers: [ReaderScreen.routeObserver],
          builder: (ctx, child) => Stack(
            children: [
              child!,
              TutorialOverlay(colors: colors),
            ],
          ),
          home: const LibraryScreen(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/ai_chat_screen.dart';
import 'screens/alarm_ring_screen.dart';
import 'screens/focus_timer_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/alarm_providers.dart';
import 'services/alarm_service.dart';
import 'services/alarm_ring_flow.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Optional for local/device configuration.
    debugPrint('No .env file found, proceeding without it.');
  }
  await StorageService.init();
  await AlarmService.init();
  await AlarmService.restoreEnabledAlarms();
  AlarmRingFlow.bindNativeAlarmEvents();
  runApp(const FlowMindApp());
}

class FlowMindApp extends StatelessWidget {
  const FlowMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.dmSansTextTheme();

    return ProviderScope(
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'FlowMind',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          colorScheme: const ColorScheme.light(
            surface: Colors.white,
            primary: Color(0xFF22C55E),
            secondary: Color(0xFF94A3B8),
          ),
          textTheme: baseTextTheme.copyWith(
            headlineLarge: GoogleFonts.spaceGrotesk(
              fontSize: 44,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            headlineMedium: GoogleFonts.spaceGrotesk(
              fontSize: 34,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            titleLarge: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            bodyLarge: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
            bodyMedium: GoogleFonts.dmSans(
              fontSize: 16,
              color: const Color(0xFF334155),
            ),
            bodySmall: GoogleFonts.dmSans(
              fontSize: 13,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
          ),
        ),
        routes: {
          '/': (_) => const SplashScreen(),
          '/app': (_) => const MainScaffold(),
          FocusTimerScreen.routeName: (_) => const FocusTimerScreen(),
          AiChatScreen.routeName: (_) => const AiChatScreen(),
          AlarmRingScreen.routeName: (_) => const AlarmRingScreen(),
          SplashScreen.routeName: (_) => const SplashScreen(),
        },
      ),
    );
  }
}

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTabIndex = ref.watch(currentTabIndexProvider);

    final pages = <Widget>[
      const HomeScreen(),
      const InsightsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[currentTabIndex].animate().fadeIn(
        duration: 280.ms,
        curve: Curves.easeOut,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex,
        onTap: (index) {
          ref.read(currentTabIndexProvider.notifier).state = index;
        },
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_rounded),
            label: 'ALARMS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'INSIGHTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }
}

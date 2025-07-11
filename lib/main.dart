import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_language_provider.dart';
import 'providers/app_theme_provider.dart';
import 'providers/user_provider.dart';

import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/client_home_screen.dart';
import 'screens/tutor_list_screen.dart';
import 'screens/tutor_profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/contact_developer_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/other_user_profile_screen.dart';
import 'screens/teaching_center_list_screen.dart';
import 'screens/teaching_center_profile_screen.dart'; // Янги экранни импорт қилиш
import 'screens/requests_screen.dart';
import 'package:repetitor_resurs/screens/bookmarked_tutors_screen.dart'; // Янги импорт
import 'package:repetitor_resurs/screens/bookmarked_teaching_centers_screen.dart'; // Янги импорт

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  final userProvider = UserProvider();
  await userProvider.setUser(FirebaseAuth.instance.currentUser);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLanguageProvider()),
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool hasSeenOnboarding;

  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<UserProvider>(context, listen: false).setUser(user);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguageProvider>(context);
    final appTheme = Provider.of<AppThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoadingProfile) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context).translate('loading')),
              ],
            ),
          ),
        ),
      );
    }

    Widget initialRoute;
    if (!widget.hasSeenOnboarding) {
      initialRoute = const OnboardingScreen();
    } else if (userProvider.firebaseUser == null) {
      initialRoute = const AuthScreen();
    } else {
      initialRoute = const ClientHomeScreen();
    }

    return MaterialApp(
      title: 'RepeitorResurs',
      debugShowCheckedModeBanner: false,
      theme: appTheme.lightTheme,
      darkTheme: appTheme.darkTheme,
      themeMode: appTheme.themeMode,
      locale: appLanguage.appLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: initialRoute,
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/client_home': (context) => const ClientHomeScreen(),
        '/tutor_list': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic> &&
              args.containsKey('teachingCenterId')) {
            return TutorListScreen(teachingCenterId: args['teachingCenterId']);
          }
          return const TutorListScreen();
        },
        '/tutor_profile': (context) {
          final String? tutorId =
              ModalRoute.of(context)?.settings.arguments as String?;
          return TutorProfileScreen(tutorId: tutorId);
        },
        '/chat': (context) => ChatScreen(
            tutorData: ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>),
        '/resources': (context) => const ResourcesScreen(),
        '/contact': (context) => const ContactDeveloperScreen(),
        '/my_profile': (context) => const MyProfileScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/chat_list': (context) => const ChatListScreen(),
        '/other_user_profile': (context) => OtherUserProfileScreen(
            userId: ModalRoute.of(context)!.settings.arguments as String),
        '/teaching_center_list': (context) => const TeachingCenterListScreen(),
        '/teaching_center_profile': (context) => TeachingCenterProfileScreen(
            centerId: ModalRoute.of(context)!.settings.arguments
                as String), // Янги маршрут
        '/requests': (context) => const RequestsScreen(),
        '/bookmarked_tutors': (context) =>
            const BookmarkedTutorsScreen(), // Янги маршрут
        '/bookmarked_teaching_centers': (context) =>
            const BookmarkedTeachingCentersScreen(), // Янги маршрут
      },
    );
  }
}

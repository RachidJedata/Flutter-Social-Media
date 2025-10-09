import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nurox_chat/components/life_cycle_event_handler.dart';
import 'package:nurox_chat/landing/landing_page.dart';
import 'package:nurox_chat/screens/mainscreen.dart';
import 'package:nurox_chat/utils/constants.dart';
import 'package:nurox_chat/utils/providers.dart';
import 'package:nurox_chat/view_models/theme/theme_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); //Initialisation du Firebase
  runApp(
    // Lancement de  l'application
    ChangeNotifierProvider(
      //
      create: (_) => ThemeProvider(), //Notification des changement de theme
      child: MyApp(),
    ),
  );
}

// Classe principale de l'application
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState(); //
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // 1. Initialize 'currentUserId' normally
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // 2. Declare '_userService' as a late field
  late final LifecycleEventHandler _userService;

  @override
  void initState() {
    // initState must NOT be async
    super.initState();

    // 3. Initialize '_userService' inside initState where all fields are ready
    _userService = LifecycleEventHandler(currentUserId: currentUserId);

    WidgetsBinding.instance.addObserver(this);

    if (currentUserId != null) {
      // Call async method without await. It's a fire-and-forget action.
      // This is generally acceptable for non-critical background updates like presence.
      _userService.updateOnlineStatus(currentUserId!, true);
    }
  }

  @override
  void dispose() {
    // CRITICAL: Set user offline when the widget is disposed
    if (currentUserId != null) {
      // Call async method without await in dispose to avoid blocking
      _userService.updateOnlineStatus(currentUserId!, false);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Contient plusieurs providers
      providers: providers,
      child: Consumer<ThemeProvider>(
        // Permet l'ecout du provider theme
        builder: (context, ThemeProvider themeProvider, Widget? child) {
          return MaterialApp(
            title: Constants.appName,
            debugShowCheckedModeBanner: false,
            theme: themeData(
              themeProvider.dark ? Constants.darkTheme : Constants.lightTheme,
            ),
            home: StreamBuilder<User?>(
              // l'ecout en temps reel de l'etat de l'utilisateur
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: ((BuildContext context, AsyncSnapshot<User?> snapshot) {
                if (snapshot.hasData) {
                  // Retourne true s'il contient data et false sinon
                  return TabScreen();
                } else
                  return Landing();
              }),
            ),
          );
        },
      ),
    );
  }

  ThemeData themeData(ThemeData theme) {
    return theme.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(
        theme.textTheme, // l'ajour du font au texte
      ),
    );
  }
}

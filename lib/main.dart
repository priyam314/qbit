import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qbit/allConstants/app_constants.dart';
import 'package:qbit/allProviders/auth_provider.dart';
import 'package:qbit/allProviders/home_provider.dart';
import 'package:qbit/allProviders/setting_provider.dart';
import 'package:qbit/allScreens/splash_page.dart';
import 'package:qbit/firebase_options.dart';
import 'package:qbit/utilities/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'allProviders/chat_provider.dart';

bool isWhite = false;

// The WidgetFlutterBinding
// is used to interact with the Flutter engine. Firebase.initializeApp() needs to
// call native code to initialize Firebase, and since the plugin needs to use platform
// channels to call the native code, which is done asynchronously therefore you have
// to call ensureInitialized() to make sure that you have an instance of the
// WidgetsBinding.
// Should be used in this way
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(MyApp());
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // SharedPreferences is what android and ios apps use to store data in an allocated
  // space. This data exists even after app is shutdown and startsup again; we
  // can still retrieve the value as it was. It stores key-value pair. Useful for
  // storing passwords, tokens, complex relational data.
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}
class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(
              pref: prefs,
              firebaseFirestore: firebaseFirestore,
              googleSignIn: GoogleSignIn(),
              firebaseAuth: FirebaseAuth.instance,
            ),
        ),
        Provider<SettingProvider>(
          create: (_) => SettingProvider(
            prefs: prefs,
            firebaseFirestore: firebaseFirestore,
            firebaseStorage: firebaseStorage
          ),
        ),
        Provider<HomeProvider>(
          create : (_) => HomeProvider(
              firebaseFirestore: firebaseFirestore
          ),
        ),
        Provider<ChatProvider>(
          create : (_) => ChatProvider(
              firebaseFirestore: firebaseFirestore,
            prefs: prefs,
            firebaseStorage: firebaseStorage
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: ThemeData(
          primaryColor: Colors.black,
        ),
        home: const SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
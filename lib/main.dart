import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qbit/allConstants/app_constants.dart';
import 'package:qbit/allProviders/auth_provider.dart';
import 'package:qbit/allProviders/setting_provider.dart';
import 'package:qbit/allScreens/splash_page.dart';
import 'package:qbit/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

bool isWhite = false;

// The above image is the architecture layers of Flutter, the WidgetFlutterBinding
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
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  MyApp({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(
              pref: this.prefs,
              firebaseFirestore: this.firebaseFirestore,
              googleSignIn: GoogleSignIn(),
              firebaseAuth: FirebaseAuth.instance,
            ),
        ),
        Provider<SettingProvider>(
        create: (_) => SettingProvider(
            prefs: this.prefs,
            firebaseFirestore: this.firebaseFirestore,
            firebaseStorage: this.firebaseStorage
        ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: ThemeData(
          primaryColor: Colors.black,
        ),
        home: SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
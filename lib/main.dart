import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:qbit/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return MaterialApp(
      title: 'qBit',
      theme: ThemeData(
        primaryColor: Colors.black,
      ),
      home: Scaffold(),
    );
  }
}
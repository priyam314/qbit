import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:firebase_auth/firebase_auth.dart";
import 'package:qbit/allConstants/constants.dart';
import 'package:qbit/allConstants/firestore_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Status{
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateCanceled,
}

class AuthProvider extends ChangeNotifier{
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFIrestore;
  final SharedPreferences pref;

  Status get status => _status;

  AuthProvider({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.firebaseFIrestore,
    required this.pref,
  });

  String? getUserFirebaseId(){
    return pref.getString(FirestoreConstants.id);
  }

  Future<bool> isLogged() async{
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn && pref.getString(FirestoreConstants.id)?.isNotEmpty == true){
      return true;
    }else{
      return false;
    }
  }
  Future<bool> handleSignIn() async{
    _status = Status.authenticating;
    notifyListeners();

    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null){
      GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? firebaseUser = (await FirebaseAuth.signInWithCredential(credential)).user;

      if (firebaseUser != null){
        final QuerySnapshot result = await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .where()
      }
    }
  }
}
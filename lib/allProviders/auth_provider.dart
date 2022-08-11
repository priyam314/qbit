import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:firebase_auth/firebase_auth.dart";
import 'package:qbit/allConstants/constants.dart';
import 'package:qbit/allConstants/firestore_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../allModels/user_chat.dart';

// With provider. you don't need to worry about callbacks or InheritedWidgets.
// But do need to understand 3 concepts.
// 1. ChangeNotifier -> it is a simple class included in flutter sdk which provides
//                      change notification to its listeners. In other words if
//                      something is a ChangeNotifier, you can subscribe to its changes
//        1.1 notifyListeners() -> call this method anytime the model changes in
//                                 a way that might change you app's UI.
//
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
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences pref;

  Status _status = Status.uninitialized;

  // getter
  Status get status => _status;

  AuthProvider({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.firebaseFirestore,
    required this.pref,
  });

  String? getUserFirebaseId(){
    return pref.getString(FirestoreConstants.id);
  }
  Future<bool> isLoggedIn() async{
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn && pref.getString(FirestoreConstants.id)?.isNotEmpty==true){
      return true;
    }
    return false;
  }
  Future<bool> handleSignIn() async{
    _status = Status.authenticating;
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();
    final AuthCredential credential;
    GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser != null) {
      GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
       credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    }else{
      _status = Status.authenticateCanceled;
      notifyListeners();
      return false;
    }

    User? firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;

    final List<DocumentSnapshot> document;

    if (firebaseUser != null) {
      // QuerySnapshot contains the result of the query, it may contain 0 or more
      // DocumentSnapshots
      // Below query search for the user with userid, but if that id doesn't exist
      final QuerySnapshot result = await firebaseFirestore
          .collection(FirestoreConstants.pathUserCollection)
          .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
          .get();
      document = result.docs;
    }else{
      _status = Status.authenticateError;
      notifyListeners();
      return false;
    }
    // This code will execute if that id is not present in fireStore, we will set
    // that data from our side in the firestore for future.
    if (document.isEmpty) {
      firebaseFirestore.collection(FirestoreConstants.pathUserCollection)
          .doc(firebaseUser.uid)
          .set({
                FirestoreConstants.nickname: firebaseUser.displayName,
                FirestoreConstants.photoUrl: firebaseUser.photoURL,
                FirestoreConstants.id: firebaseUser.uid,
                'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
                FirestoreConstants.chattingWith: null,
                FirestoreConstants.friends: <String>[firebaseUser.uid],
      });
      User? currentUser = firebaseUser;
      // setting the values of credentials in persistent storage also
      await pref.setString(FirestoreConstants.id, currentUser.uid);
      await pref.setString(FirestoreConstants.nickname, currentUser.displayName ?? "");
      await pref.setString(FirestoreConstants.photoUrl, currentUser.photoURL ?? "");
      await pref.setString(FirestoreConstants.phoneNumber, currentUser.phoneNumber ?? "");
      // await pref.setString(FirestoreConstants.friends, <String>[]);
    }else{
      DocumentSnapshot documentSnapshot = document[0];
      UserChat userChat = UserChat.fromDocument(documentSnapshot);

      await pref.setString(FirestoreConstants.id, userChat.id);
      await pref.setString(FirestoreConstants.nickname, userChat.nickName);
      await pref.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
      await pref.setString(FirestoreConstants.phoneNumber, userChat.phoneNumber);
      await pref.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
    }
    _status = Status.authenticated;
    notifyListeners();
    return true;
  }
  Future<void> handleSignOut() async {
    _status = Status.uninitialized;
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
}
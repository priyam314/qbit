import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qbit/allConstants/constants.dart';

class UserChat{
  String id;
  String photoUrl;
  String nickName;
  String aboutMe;
  String phoneNumber;

  UserChat({
    required this.phoneNumber,
    required this.photoUrl,
    required this.aboutMe,
    required this.id,
    required this.nickName,
});

  Map<String, String> toJson(){
    return {
      FirestoreConstants.nickname: nickName,
      FirestoreConstants.aboutMe: aboutMe,
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.phoneNumber: phoneNumber,
    };
  }

  factory UserChat.fromDocument(DocumentSnapshot doc){
    String aboutMe = "";
    String photoUrl = "";
    String nickname = "";
    String phoneNumber = "";
    try{
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    } catch (e) {
      log(e.toString(), name: 'user_chat');
    }
    try{
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (e) {
      log(e.toString(), name: 'user_chat');
    }
    try{
      nickname = doc.get(FirestoreConstants.nickname);
    } catch (e) {
      log(e.toString(), name: 'user_chat');
    }
    try{
      phoneNumber = doc.get(FirestoreConstants.phoneNumber);
    } catch (e) {
      log(e.toString(), name: 'user_chat');
    }
    return UserChat(
      id: doc.id,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      aboutMe: aboutMe,
      nickName: nickname,
    );
  }
}
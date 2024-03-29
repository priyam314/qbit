import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qbit/allConstants/constants.dart';
import 'package:qbit/utilities/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../allModels/message_chat.dart';

class ChatProvider{
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  ChatProvider({
    required this.firebaseStorage,
    required this.firebaseFirestore,
    required this.prefs,
  });

  UploadTask uploadFile(File image, String filename){
    // create a reference to a filename in firebase storage
    Reference reference = firebaseStorage.ref().child(filename);
    // put the file to that reference
    UploadTask uploadTask = reference.putFile(image);
    logInfo('uploadFile worked: chat_provider');
    return uploadTask;
  }
  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, dynamic> dataNeedUpdate)async {
    return await firebaseFirestore.collection(collectionPath).doc(docPath).update(dataNeedUpdate);
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit){
    return firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }
  void sendMessage(String content, int type, String groupChatId, String currentUserId, String peerId){
    DocumentReference documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    MessageChat messageChat = MessageChat(
      idFrom: currentUserId,
      idTo: peerId,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
    );
    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(documentReference, messageChat.toJson());
    });
  }
}

class TypeMessage{
  static const text = 0;
  static const image = 1;
  static const sticker = 2;
}
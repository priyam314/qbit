import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qbit/allConstants/constants.dart';

class MessageChat{
  String idFrom;
  String idTo;
  String timestamp;
  String content;
  int type;

  MessageChat({
    required this.content,
    required this.timestamp,
    required this.idFrom,
    required this.idTo,
    required this.type,
  });
  Map<String, dynamic> toJson(){
    return{
      FirestoreConstants.idFrom: idFrom,
      FirestoreConstants.content: content,
      FirestoreConstants.timestamp: timestamp,
      FirestoreConstants.type: type,
      FirestoreConstants.idTo: idTo,
    };
  }
  factory MessageChat.fromDocument(DocumentSnapshot doc){
    int type = doc.get(FirestoreConstants.type);
    String timestamp = doc.get(FirestoreConstants.timestamp);
    String content = doc.get(FirestoreConstants.content);
    String idFrom = doc.get(FirestoreConstants.idFrom);
    String idTo = doc.get(FirestoreConstants.idTo);
    return MessageChat(idFrom: idFrom, idTo: idTo, timestamp: timestamp, content: content, type: type);
  }
}
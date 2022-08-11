import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qbit/allConstants/constants.dart';

class HomeProvider {
  final FirebaseFirestore firebaseFirestore;

  HomeProvider({
    required this.firebaseFirestore
  });

  Future<void> updateDataFirestore(String collectionPath, String path,
      Map<String, String> dataNeedUpdate) {
    return firebaseFirestore.collection(collectionPath).doc(path).update(
        dataNeedUpdate);
  }

  Stream<QuerySnapshot> getStreamFirestore(String collectionPath, int limit, String? textSearch) {
    return firebaseFirestore.collection(collectionPath)
        .limit(limit)
        .where(FirestoreConstants.nickname, isGreaterThanOrEqualTo: textSearch)
        .where(FirestoreConstants.nickname, isLessThan: '${textSearch}z')
        .snapshots();
  }

  Future<QuerySnapshot> getStreamFriends(String collectionPath, String id)async {
    // print('friends: $friends, type: ${friends.runtimeType}');
    final List<String> friends = await getFriends(id);
    print('friends: $friends');
    return firebaseFirestore
        .collection(collectionPath)
        .where(FirestoreConstants.id, whereIn: friends)
        .get();
  }

  Future<List<String>> getFriends(String id) async {
    List<String> friendsList = [];
    await firebaseFirestore
        .collection(FirestoreConstants.pathUserCollection)
        .where("id", isEqualTo: id)
        .get()
        .then((QuerySnapshot querySnapshot) {
          //print('yo yo type: ${querySnapshot.docs[0].get(FirestoreConstants.friends) }');
          for(var iid in querySnapshot.docs[0].get(FirestoreConstants.friends)){
            print ('friend: $iid');
            friendsList.add(iid);
          }
        })
        .catchError((e) => print('error $e'));
    return friendsList;
  }
  Future<void> addFriends(String id, String friendId) async {
    print("adding friend");
    return await firebaseFirestore
        .collection(FirestoreConstants.pathUserCollection)
        .doc(id)
        .update({FirestoreConstants.friends: FieldValue.arrayUnion(<String>[friendId])})
        .then((_)=>print("done adding friend"));
  }
  Future<void> addToFriend(String id, String friendId) async {
    print("adding to friend");
    return await firebaseFirestore
        .collection(FirestoreConstants.pathUserCollection)
        .doc(friendId)
        .update({FirestoreConstants.friends: FieldValue.arrayUnion(<String>[id])})
        .then((_)=>print("done adding to friend"));
  }
}


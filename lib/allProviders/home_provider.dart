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

  Stream<QuerySnapshot> getStreamFirestore(String collectionPath, int limit,
      String? textSearch) {
    return firebaseFirestore.collection(collectionPath)
        .limit(limit).where(FirestoreConstants.nickname, isEqualTo: textSearch)
        .snapshots();
  }

  List<String> getFriends(String id)  {
    List<String> friendsList = [];
    firebaseFirestore
        .collection(FirestoreConstants.pathUserCollection)
        .where("id", isEqualTo: id)
        .get()
        .then((QuerySnapshot querySnapshot) {
          print('yo yo type: ${querySnapshot.docs[0].get(FirestoreConstants.friends) }');
          for(var iid in querySnapshot.docs[0].get(FirestoreConstants.friends)){
            print (iid);
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
}


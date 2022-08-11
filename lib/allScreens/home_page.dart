import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:qbit/allConstants/app_constants.dart';
import 'package:qbit/allConstants/constants.dart';
import 'package:qbit/allModels/user_chat.dart';
import 'package:qbit/allWidgets/loading_view.dart';

import '../allModels/popup_choices.dart';
import '../allProviders/auth_provider.dart';
import '../allProviders/home_provider.dart';
import '../main.dart';
import '../utilities/debouncer.dart';
import '../utilities/utilities.dart';
import 'chat_page.dart';
import 'full_photo_state.dart';
import 'login_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  int limit = 20;
  final int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late AuthProvider authProvider;
  late HomeProvider homeProvider;
  late String currentUserId;

  Debouncer searchDebouncer = Debouncer(milliseconds: 300);
  // A StreamController gives you a new stream and a way to add events to the
  // stream at any point, and from anywhere. The stream has all the logic necessary
  // to handle listeners and pausing. You return the stream and keep the controller
  // to yourself.
  StreamController<bool> btnClearController = StreamController<bool>();
  TextEditingController searchBarTec = TextEditingController();

  List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: "settings", icon: Icons.settings),
    PopupChoices(title: "Sign out", icon: Icons.exit_to_app),
  ];

  Future<void> handleSignOut()async{
    authProvider.handleSignOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }
  void onItemMenuPress(PopupChoices choice){
    if (choice.title == "Sign out"){
      handleSignOut();
    }else{
      Navigator.push(context, MaterialPageRoute(builder: (context)=>const SettingsPage()));
    }
  }

  Future<bool> onBackPress(){
    openDialog();
    return Future.value(false);
  }
  Future<void> openDialog() async{
    switch(await showDialog(
        context: context,
        builder: (BuildContext context){
          return SimpleDialog(
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                color: ColorConstants.themeColor,
                padding: const EdgeInsets.only(bottom: 10, top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: const Icon(
                        Icons.exit_to_app,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Exit App',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: (){
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: const Icon(
                        Icons.cancel,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                    const Text(
                      'Cancel',
                      style: TextStyle(color: ColorConstants.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: (){
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      'Yes',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
    )){
      case 0:
        break;
      case 1:
        exit(0);
    }
  }
  void scrollListener(){
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange){
      setState((){
        limit += _limitIncrement;
      });
    }
  }

  @override
  void initState(){
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true){
      currentUserId = authProvider.getUserFirebaseId()!;
    }else{
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
      );
    }
    listScrollController.addListener(scrollListener);
  }

  Widget buildPopupMenu(){
    return PopupMenuButton<PopupChoices>(
        onSelected: onItemMenuPress,
        icon: const Icon(Icons.more_vert, color: ColorConstants.primaryColor),
        itemBuilder: (BuildContext context){
      return choices.map((PopupChoices choice){
        return PopupMenuItem<PopupChoices>(
          value: choice,
          child: Row(
            children: <Widget>[
              Icon(
                choice.icon,
                color: ColorConstants.primaryColor,
              ),
              Container(
                width: 10,
              ),
              Text(
                choice.title,
                style: const TextStyle(color: ColorConstants.primaryColor),
              ),
            ]
          )
        );
      }).toList();
    });
  }

  @override
  void dispose(){
    super.dispose();
    btnClearController.close();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: ColorConstants.primaryColor,
        child: const Icon(
          Icons.group_add,
          color: Colors.white70,
        ),
      ),
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        centerTitle: true,
        titleTextStyle: const TextStyle(
            color: ColorConstants.primaryColor,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          fontSize: 20.0
        ),
        backgroundColor: isWhite ? Colors.white:Colors.black,
        leading: IconButton(
          icon: Switch(
            value: isWhite,
            onChanged: (value){
              setState((){
                isWhite = value;
                // print(isWhite);
              });
            },
            activeTrackColor: Colors.grey,
            activeColor: Colors.white,
            inactiveTrackColor: Colors.grey,
            inactiveThumbColor: Colors.black45,
          ),
          onPressed: ()=>"",
        ),
        actions: <Widget>[
          buildPopupMenu(),
        ],
      ),
      body: buildWillPopScope(),
    );
  }

  WillPopScope buildWillPopScope() {
    return WillPopScope(
      onWillPop: onBackPress,
      child: Stack(
        children: <Widget>[
          Column(
            children: [
              buildSearchBar(),
              BuildEntity(homeProvider: homeProvider, listScrollController: listScrollController)
                  .over(_textSearch, limit, currentUserId),
            ],
          ),
          Positioned(
              child: isLoading ? const LoadingView() : const SizedBox.shrink(),
          ),
        ]
      ),
    );
  }

  Widget buildSearchBar(){
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ColorConstants.greyColor2,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.search, color: ColorConstants.greyColor, size: 20),
          const SizedBox(width: 5),
          Expanded(
            child: TextFormField(
              textInputAction: TextInputAction.search,
              controller: searchBarTec,
              onChanged: (value){
                if(value.isNotEmpty){
                  btnClearController.add(true);
                  setState((){
                    _textSearch = value;
                  });
                }else{
                  btnClearController.add(false);
                  setState((){
                    _textSearch = "";
                  });
                }
              },
              decoration: const InputDecoration.collapsed(
                  hintText: 'Search here...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: ColorConstants.greyColor,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          StreamBuilder(
              stream: btnClearController.stream,
              builder: (context, snapshot){
                return snapshot.data == true
                    ? GestureDetector(
                        onTap: (){
                          searchBarTec.clear();
                          btnClearController.add(false);
                          setState((){
                            _textSearch = "";
                          });
                        },
                        child: const Icon(
                          Icons.clear_rounded,
                          color: ColorConstants.greyColor,
                          size: 20
                        ),
                     )
                    :const SizedBox.shrink();
              }
          ),
        ],
      ),
    );
  }


}
Widget buildItem(BuildContext context, DocumentSnapshot? document, String currentUserId){
  if (document == null) {
    return const SizedBox.shrink();
  }
  UserChat userChat = UserChat.fromDocument(document);
  // if (userChat.id == currentUserId){
  //     return const Center(child: Text(
  //           'No User Found!', style: TextStyle(color: Colors.grey)));
  // }
  return Card(
    margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
    child: TextButton(
      onPressed: () {
        if (Utilities.isKeyboardShowing()){
          Utilities.closeKeyboard(context);
        }
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(
            peerId: userChat.id,
            peerAvatar: userChat.photoUrl,
            peerNickname: userChat.nickName
        )));
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.grey.withOpacity(0.2)),
        shape: MaterialStateProperty.all<OutlinedBorder>(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Material(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            clipBehavior: Clip.hardEdge,
            child: userChat.photoUrl.isNotEmpty
                ? GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => FullPhotoPage(url: userChat.photoUrl)));
              },
                  child: Image.network(
                    userChat.photoUrl,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                      if (loadingProgress==null) return child;
                      return SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: Colors.grey,
                          value: loadingProgress.expectedTotalBytes != null &&
                              loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded/loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, object, stackTrace){
                      return const Icon(
                        Icons.account_circle,
                        size: 50,
                        color: ColorConstants.greyColor,
                      );
                    },
            ),
                )
                : const Icon(
              Icons.account_circle,
              size: 50,
              color: ColorConstants.greyColor,
            ),
          ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(left: 20),
              child: Column(
                children: <Widget>[
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.fromLTRB(10, 0, 0, 5),
                    child: Text(
                      userChat.nickName,
                      maxLines: 1,
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Text(
                      userChat.aboutMe,
                      maxLines: 1,
                      style: TextStyle(color: Colors.grey[700],),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class BuildEntity{
  final HomeProvider homeProvider;
  final ScrollController listScrollController;

  BuildEntity({Key? key, required this.homeProvider, required this.listScrollController});

  Widget over(String textSearch, int limit, String currentUserId){
    BuildEntityTruth buildEntityTruth = BuildEntityTruth(homeProvider: homeProvider, listScrollController: listScrollController);
    if (textSearch.trim().isNotEmpty) {
      return buildEntityTruth.build(limit, textSearch, currentUserId);
    }
    return BuildEntityNull(homeProvider: homeProvider, listScrollController: listScrollController, currentUserId: currentUserId,);
  }
}
class BuildEntityNull extends StatefulWidget {
  final HomeProvider homeProvider;
  final ScrollController listScrollController;
  final String currentUserId;
  const BuildEntityNull({
    required this.homeProvider,
    required this.listScrollController,
    required this.currentUserId});

  @override
  State<BuildEntityNull> createState() => _BuildEntityNullState();
}
class _BuildEntityNullState extends State<BuildEntityNull> {
  @override
  Widget build(BuildContext context) {
    print('currentUserId: ${widget.currentUserId}');
    return Expanded(
      child: FutureBuilder<QuerySnapshot<dynamic>>(
        future: widget.homeProvider.getStreamFriends(
            FirestoreConstants.pathUserCollection, widget.currentUserId),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.docs.isNotEmpty) {
              print('snapshot stream: ${snapshot.data!.docs}');
              return ListView.builder(
                itemBuilder: (context, index) =>
                    buildItem(context, snapshot.data!.docs[index], widget.currentUserId),
                itemCount: snapshot.data!.docs.length,
                controller: widget.listScrollController,
              );
            } else {
              return const Center(child: Text(
                  'No User Found!', style: TextStyle(color: Colors.grey)));
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.grey,
              ),
            );
          }
        },
      ),
    );
  }
}

// class BuildEntityNull{
//   final HomeProvider homeProvider;
//   final ScrollController listScrollController;
//
//   BuildEntityNull({
//     Key? key,
//     required this.homeProvider,
//     required this.listScrollController,
//     required this.currentUserId});
//
//   Widget build(String currentUserId) {
//     print('currentUserId: $currentUserId');
//     return FutureBuilder<List<String>>(
//       future: homeProvider.getFriends(currentUserId),
//       builder: (BuildContext context, AsyncSnapshot<List<String>> snapShot){
//         if (snapShot.hasData){
//           print('snapShot.data: ${snapShot.data}');
//           if (snapShot.data!.isNotEmpty){
//             final List<String>? friendList = snapShot.data;
//             print('friendList: $friendList');
//             return Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: homeProvider.getStreamFriends(
//                     FirestoreConstants.pathUserCollection, friendList),
//                 builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
//                   if(snapshot.hasData){
//                     if(snapshot.data!.docs.isNotEmpty){
//                       print('snapshot stream: ${snapshot.data!.docs}');
//                       return ListView.builder(
//                         itemBuilder: (context, index) => buildItem(context, snapshot.data!.docs[index]),
//                         itemCount: snapshot.data!.docs.length,
//                         controller: listScrollController,
//                       );
//                     }else{
//                       return const Center(child: Text('No User Found!', style: TextStyle(color: Colors.grey)));
//                     }
//                   }else{
//                     return const Center(
//                       child: CircularProgressIndicator(
//                         color: Colors.grey,
//                       ),
//                     );
//                   }
//                 },
//               ),
//             );
//           }else{
//             return const Center(child: Text('No Friends Found!', style: TextStyle(color: Colors.grey)));
//           }
//         }
//         return const LoadingView();
//       },
//     );
//   }
// }

class BuildEntityTruth{
  final HomeProvider homeProvider;
  final ScrollController listScrollController;
  BuildEntityTruth({Key? key, required this.homeProvider, required this.listScrollController});

  Widget build(int limit, String textSearch, String currentUserId){
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: homeProvider.getStreamFirestore(
            FirestoreConstants.pathUserCollection, limit, textSearch),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
          if(snapshot.hasData){
            if(snapshot.data!.docs.isNotEmpty){
              return ListView.builder(
                itemBuilder: (context, index) => buildItem(context, snapshot.data!.docs[index], currentUserId),
                itemCount: snapshot.data!.docs.length,
                controller: listScrollController,
              );
            }else{
              return const Center(child: Text('No User Found!', style: TextStyle(color: Colors.grey)));
            }
          }else{
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.grey,
              ),
            );
          }
        },
      ),
    );
  }
}



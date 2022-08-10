// import 'dart:ffi';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qbit/allConstants/constants.dart';
import 'package:qbit/allProviders/auth_provider.dart';
import 'package:qbit/allProviders/home_provider.dart';
import 'package:qbit/allProviders/setting_provider.dart';
import 'package:qbit/allScreens/full_photo_state.dart';
import 'package:qbit/allScreens/home_page.dart';
import 'package:qbit/allScreens/login_page.dart';
import 'package:qbit/allWidgets/loading_view.dart';
import 'package:qbit/utilities/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../allModels/message_chat.dart';
import '../allProviders/chat_provider.dart';
import '../main.dart';

class ChatPage extends StatefulWidget {

  final String peerId;
  final String peerAvatar;
  final String peerNickname;

  const ChatPage({Key? key, required this.peerId, required this.peerAvatar, required this.peerNickname}) : super(key: key);

  @override
  ChatPageState createState() => ChatPageState(
    peerId: peerId,
    peerAvatar: peerAvatar,
    peerNickname: peerNickname
  );
}

class ChatPageState extends State<ChatPage> {
  String? peerId;
  String? peerAvatar;
  String? peerNickname;
  ChatPageState({Key? key, required this.peerId, required this.peerNickname, required this.peerAvatar});
  late String currentUserId;
  List<QueryDocumentSnapshot> listMessage = List.from([]);
  int limit = 20;
  final int _limitIncrement = 20;
  String groupChatId = "";

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;
  late HomeProvider homeProvider;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();
    homeProvider= context.read<HomeProvider>();
    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    readLocal();
  }
  _scrollListener(){
    if(listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange){
      setState((){
        limit += _limitIncrement;
      });
    }
  }
  void onFocusChange(){
    if (focusNode.hasFocus){
      setState((){
        isShowSticker = false;
      });
    }
  }
  void readLocal(){
    if(authProvider.getUserFirebaseId()?.isNotEmpty == true){
      currentUserId = authProvider.getUserFirebaseId()!;
    }else{
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context)=>const LoginPage()),
              (Route<dynamic> route) => false
      );
    }
    print('currentUser id $currentUserId');
    print('peer Id $peerId');
    if (currentUserId.hashCode <= peerId.hashCode){
      groupChatId = '$currentUserId-$peerId';
    }else{
      groupChatId = '$peerId-$currentUserId';
    }
    print('groupChat id $groupChatId');
    chatProvider.updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        currentUserId,
        {FirestoreConstants.chattingWith: peerId}
    );
  }
  Future getImage() async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
    }else{
      logError('no file being picked');
    }
    if (imageFile!=null){
      setState((){
        isLoading = true;
      });
      logInfo('getImage worked: chat_page');
      uploadFile();
    }
  }
  void getSticker(){
    focusNode.unfocus();
    setState((){
      isShowSticker = !isShowSticker;
    });
  }
  Future uploadFile() async {
    String filename = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!, filename);
    try{
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState((){
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
      } on FirebaseException catch(e) {
      setState((){
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }
  void onSendMessage(String content, int type){
    if (content.trim().isNotEmpty){
      textEditingController.clear();
      chatProvider.sendMessage(content, type, groupChatId, currentUserId, peerId!);
      homeProvider.addFriends(currentUserId, peerId!);
      listScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }else{
      Fluttertoast.showToast(msg: 'Nothing To Send', backgroundColor: ColorConstants.greyColor);
    }
  }
  bool isLastMessageLeft(int index){
    if(index>0 && listMessage[index-1].get(FirestoreConstants.idFrom)==currentUserId || index==0){
      return true;
    }
    return false;
  }
  bool isLastMessageRight(int index){
    if(index>0 && listMessage[index-1].get(FirestoreConstants.idFrom)!=currentUserId || index==0){
      return true;
    }
    return false;
  }
  Future<bool> onBackPress(){
    if(isShowSticker){
      setState((){
        isShowSticker = false;
      });
    }else{
      chatProvider.updateDataFirestore(
          FirestoreConstants.pathUserCollection,
          currentUserId,
          {FirestoreConstants.chattingWith: null}
      );
      Navigator.pop(context);
    }
    return Future.value(false);
  }
  void _callPhoneNumber(String callPhoneNumber) async {
    var uri = Uri.parse('tel://$callPhoneNumber');
    if (await canLaunchUrl(uri)){
      await launchUrl(uri);
    }else{
      throw 'Error occurred';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
          backgroundColor: isWhite ? Colors.white : Colors.grey[900],
          iconTheme: const IconThemeData(
            color: ColorConstants.primaryColor,
          ),
        title: Text(
          peerNickname!,
          style: const TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.phone_iphone,size: 30,
              color: ColorConstants.primaryColor,
            ),
            onPressed: (){
              SettingProvider settingProvider;
              settingProvider = context.read<SettingProvider>();
              String callPhoneNumber = settingProvider.getPref(FirestoreConstants.phoneNumber) ?? "";
              _callPhoneNumber(callPhoneNumber);
            },
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                buildListMessage(),
                isShowSticker ? buildSticker() : const SizedBox.shrink(),
                buildInput(),
              ],
            ),
            buildLoading(),
          ],
        ),
      ),
    );
  }
  Widget buildSticker(){
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(5),
        height: 180,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment:  MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi1.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                      'images/mimi1.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                      'images/mimi1.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                      'images/mimi1.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                      'images/mimi1.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                      'images/mimi1.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                      'images/mimi1.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                      'images/mimi1.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                      'images/mimi1.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget buildLoading(){
    return Positioned(
        child: isLoading ? const LoadingView() : const SizedBox.shrink(),
    );
  }
  Widget buildInput(){
    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: ColorConstants.greyColor2,
            width: 0.5
          ),
        ),
      ),
      // color: Colors.white,
      child: Row(
        children: <Widget>[
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: const Icon(Icons.camera_enhance),
                onPressed: getImage,
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: const Icon(Icons.face_retouching_natural),
                onPressed: getSticker,
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
          Flexible(
            child: TextField(
              onSubmitted: (value){
                onSendMessage(textEditingController.text, TypeMessage.text);
              },
              style: const TextStyle(color: ColorConstants.primaryColor, fontSize: 15),
              controller: textEditingController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type Your Message...',
                hintStyle: TextStyle(color: ColorConstants.greyColor),
              ),
              focusNode: focusNode,
            ),
          ),
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: ()=>onSendMessage(textEditingController.text, TypeMessage.text),
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget buildItem(int index, DocumentSnapshot? document){
    // text message area for sender
    if(document == null) {
      return const SizedBox.shrink();
    }
    MessageChat messageChat = MessageChat.fromDocument(document);
    if(messageChat.idFrom == currentUserId){
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          messageChat.type == TypeMessage.text
          ? Container(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            width: 200,
            decoration: BoxDecoration(
                color: ColorConstants.greyColor2,
                borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
            child: Text(
              messageChat.content,
              style: const TextStyle(color: ColorConstants.primaryColor),
            ),
          )
              : messageChat.type == TypeMessage.image
                ? Container(
                    margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20: 10, right: 10),
                    child: OutlinedButton(
                      onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => FullPhotoPage(url: messageChat.content)));
                      },
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(0)),
                      ),
                      child: Material(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        clipBehavior: Clip.hardEdge,
                        child: Image.network(
                          messageChat.content,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                            if(loadingProgress == null) return child;
                            return Container(
                              decoration: const BoxDecoration(
                                color: ColorConstants.greyColor2,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              width: 200,
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.themeColor,
                                  value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace){
                            return Material(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Image.asset(
                                'images/img_not_available.jpeg',
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
          )
              : Container(
                  margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
                  child: Image.asset(
                    'images/${messageChat.content}.gif',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          )
        ],
      );
    }else{
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          //crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                isLastMessageLeft(index)
                ? Material(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.network(
                    peerAvatar!,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress ){
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: ColorConstants.themeColor,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, object, stackStrace){
                      return const Icon(
                        Icons.account_circle,
                        size: 35,
                        color: ColorConstants.greyColor,
                      );
                    },
                    width: 35,
                    height: 35,
                    fit: BoxFit.cover,
                  ),
                ) : Container(
                  width: 35,
                ),
                messageChat.type == TypeMessage.text
                ? Container(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  width: 200,
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.only(left: 10),
                  child: Text(
                    messageChat.content,
                    style: const TextStyle(color: Colors.white),
                  ),
                ): messageChat.type == TypeMessage.image
                ? Container(
                  margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20: 10, right: 10),
                  child: TextButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FullPhotoPage(url: messageChat.content)));
                    },
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(0)),
                    ),
                    child: Material(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      clipBehavior: Clip.hardEdge,
                      child: Image.network(
                        messageChat.content,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                          if(loadingProgress == null) return child;
                          return Container(
                            decoration: const BoxDecoration(
                              color: ColorConstants.greyColor2,
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            width: 200,
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: ColorConstants.themeColor,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, object, stackTrace) => Material(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.asset(
                            'images/img_not_available.jpeg',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover
                          ),
                        ),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ): Container(
                  margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20: 10, right: 10),
                  child: Image.asset(
                    'images/${messageChat.content}.gif',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            isLastMessageLeft(index)
            ? Container(
              margin: const EdgeInsets.only(left: 50, top: 5, bottom: 5),
              child: Text(
                DateFormat("dd MM yyyy, hh:mm a")
                    .format(DateTime.fromMillisecondsSinceEpoch(int.parse(messageChat.timestamp))),
                style: const TextStyle(color: ColorConstants.greyColor, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ): const SizedBox.shrink()
          ],
        ),
      );
    }
  }

  // It’s a means to respond to an asynchronous procession of data. A StreamBuilder
  // Widget is a StatefulWidget, and so is able to keep a ‘running summary’ and
  // or record and note the ‘latest data item’ from a stream of data. In most cases,
  // the StreamBuilder takes in the latest ‘data event’ (the latest encountered
  // of a data item from the stream) to determine the next widget to be built.
  Widget buildListMessage(){
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatStream(groupChatId, limit),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                if (snapshot.hasData){
                  listMessage.addAll(snapshot.data!.docs);
                  // ListView is a very important widget in a flutter. It is used
                  // to create the list of children But when we want to create a
                  // list recursively without writing code again and again then
                  // ListView.builder is used instead of ListView.  ListView.builder
                  // creates a scrollable, linear array of widgets.
                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (context, index) => buildItem(index, snapshot.data?.docs[index]),
                    itemCount: snapshot.data?.docs.length,
                    reverse: true,
                    controller: listScrollController
                  );
                }else{
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.themeColor,
                    ),
                  );
                }
              },
      )
          : const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.themeColor,
        ),
      ),
    );
  }
}

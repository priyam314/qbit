import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qbit/allConstants/constants.dart';

import '../allConstants/app_constants.dart';
import '../allModels/user_chat.dart';
import '../allProviders/setting_provider.dart';
import '../main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: const Text(
          AppConstants.settingsTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
    );
  }
}

class SettingsPageState extends StatefulWidget {
  const SettingsPageState({Key? key}) : super(key: key);

  @override
  State<SettingsPageState> createState() => _SettingsPageStateState();
}

class _SettingsPageStateState extends State<SettingsPageState> {

  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;

  String dialCodeDigits = "+00";
  final TextEditingController _controller = TextEditingController();

  String id = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';
  String phoneNumber = '';

  bool isLoading = false;
  File? avatarImageFile;
  late SettingProvider settingProvider;

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    settingProvider = context.read<SettingProvider>();
    readLocal();
  }

  void readLocal(){
    setState((){
      id = settingProvider.getPref(FirestoreConstants.id)??"";
      nickname = settingProvider.getPref(FirestoreConstants.nickname)??"";
      photoUrl = settingProvider.getPref(FirestoreConstants.photoUrl)??"";
      aboutMe = settingProvider.getPref(FirestoreConstants.aboutMe)??"";
      phoneNumber = settingProvider.getPref(FirestoreConstants.phoneNumber)??"";
    });

    controllerNickname = TextEditingController(
      text: nickname,
    );
    controllerAboutMe = TextEditingController(
      text: aboutMe,
    );
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile? pickedFile = await imagePicker.getImage(source: ImageSource.gallery).catchError((err){
      Fluttertoast.showToast(msg: err.toString());
    });
    File? image;
    if (pickedFile!=null){
      image = File(pickedFile.path);
    }
    if (image != null){
      setState((){
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }
  Future uploadFile() async {
    String filename = id;
    UploadTask uploadTask = settingProvider.uploadFile(avatarImageFile!, filename);
    try{
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();
      UserChat updateinfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        nickName: nickname,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber,
      );
      settingProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, id, updateinfo.toJson())
      .then((data) async {
        await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
      }).catchError((err){
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    }on FirebaseException catch(err){
      setState((){
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.message ?? err.toString());
    }
  }
  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();
    setState(() {
      isLoading = true;
      if (dialCodeDigits != "+00" && _controller.text != "") {
        phoneNumber = dialCodeDigits + _controller.text.toString();
      }
    });
    UserChat updateinfo = UserChat(
      id: id,
      photoUrl: photoUrl,
      nickName: nickname,
      aboutMe: aboutMe,
      phoneNumber: phoneNumber,
    );
    settingProvider.updateDataFirestore(
        FirestoreConstants.pathUserCollection, id, updateinfo.toJson())
        .then((data) async {
      await settingProvider.setPref(FirestoreConstants.nickname, nickname);
      await settingProvider.setPref(FirestoreConstants.aboutMe, aboutMe);
      await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
      await settingProvider.setPref(
          FirestoreConstants.phoneNumber, phoneNumber);

    setState(() {
      isLoading = false;
    });
    Fluttertoast.showToast(msg: "update success");
  }).catchError((err){
    setState((){
      isLoading = false;
  });
    Fluttertoast.showToast(msg: err.toString());
  });
  }
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}


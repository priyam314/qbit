import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qbit/allConstants/constants.dart';
import 'package:qbit/allWidgets/loading_view.dart';

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
      body: SettingsPageState(),
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
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                onPressed: getImage,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: avatarImageFile == null
                    ? photoUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      width: 90,
                      height: 90,
                      errorBuilder: (context, object, stackTrace){
                        return const Icon(
                          Icons.account_circle,
                          size: 90,
                          color: ColorConstants.greyColor,
                        );
                      },
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                        if (loadingProgress==null) return child;
                        return Container(
                          width: 90,
                          height: 90,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.grey,
                              value: loadingProgress.expectedTotalBytes != null &&
                                loadingProgress.expectedTotalBytes != null ?
                                  loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  :null,
                            ),
                          ),
                        );
                      },
                    ),
                  ) : const Icon(
                    Icons.account_circle,
                    size: 90,
                    color: ColorConstants.greyColor,
                  )
                      :ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Image.file(
                      avatarImageFile!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                    margin: EdgeInsets.only(left: 10, bottom: 5, top: 10),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10, right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ColorConstants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ColorConstants.primaryColor),
                          ),
                          hintText: "Write Your Name...",
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: ColorConstants.greyColor),
                        ),
                        controller: controllerNickname,
                        onChanged: (value){
                          nickname = value;
                        },
                        focusNode: focusNodeNickname,
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      'About Me',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                    margin: EdgeInsets.only(left: 10, top: 30, bottom: 5),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10, right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ColorConstants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ColorConstants.primaryColor),
                          ),
                          hintText: "Write some thing about yourself...",
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: ColorConstants.greyColor),
                        ),
                        controller: controllerAboutMe,
                        onChanged: (value){
                          aboutMe = value;
                        },
                        focusNode: focusNodeAboutMe,
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      'Phone Number',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                    margin: EdgeInsets.only(left: 10, top: 30, bottom: 5),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10, right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: phoneNumber,
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10, top: 30, bottom: 5),
                    child: SizedBox(
                      width: 400,
                      height: 60,
                      child: CountryCodePicker(
                        onChanged: (country){
                          setState((){
                            dialCodeDigits = country.dialCode!;
                          });
                        },
                        initialSelection: "IT",
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        favorite: ["+1", "US", "+91", "IND"],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: TextField(
                      style: TextStyle(color: Colors.grey),
                      decoration: InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.greyColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor),
                        ),
                        hintText: "Phone Number",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefix: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(dialCodeDigits, style: TextStyle(color: Colors.grey),),
                        ),
                      ),
                      maxLength: 12,
                      keyboardType: TextInputType.number,
                      controller: _controller
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 50, bottom: 50),
                child: TextButton(
                  onPressed: handleUpdateData,
                  child: Text(
                    'update me',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(ColorConstants.primaryColor),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.fromLTRB(30,10,30,10),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        Positioned(child: isLoading ? LoadingView(): const SizedBox.shrink()),
      ],
    );
  }
}
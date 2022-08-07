import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:qbit/allConstants/constants.dart';

import '../allModels/popup_choices.dart';
import '../allProviders/auth_provider.dart';
import '../allProviders/home_provider.dart';
import '../main.dart';
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

  int _limit = 20;
  int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late AuthProvider authProvider;
  late HomeProvider homeProvider;
  late String currentUserId;

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

  void scrollListener(){
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange){
      setState((){
        _limit += _limitIncrement;
      });
    }
  }

  @override
  void initState(){
    super.initState();
    authProvider = context.read<AuthProvider>();
    // homeProvider = context.read<HomeProvider>();
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
        icon: const Icon(Icons.more_vert, color: Colors.redAccent),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white:Colors.black,
        leading: IconButton(
          icon: Switch(
            value: isWhite,
            onChanged: (value){
              setState((){
                isWhite = value;
                print(isWhite);
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
    );
  }
}

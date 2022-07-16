import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qbit/allConstants/constants.dart';
import 'package:qbit/allProviders/auth_provider.dart';
import 'package:qbit/allScreens/home_page.dart';
import 'package:qbit/allScreens/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override

    void initState() {
    // TODO: implement initState
    super.initState();
    // show splash screen for 5 seconds, then redirect to login page or home page
    Future.delayed(Duration(seconds: 10), (){
      checkSignedIn();
    });
  }
  void checkSignedIn() async {
    AuthProvider authProvider = context.read<AuthProvider>();
    bool isLoggedIn = await authProvider.isLoggedIn();
    if (isLoggedIn){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "images/splash.png",
              width: 300,
              height: 300,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "World's Coolest Chat App",
              style: TextStyle(
                color: ColorConstants.themeColor,
                fontSize: 20.9,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: ColorConstants.themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

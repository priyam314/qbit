import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:qbit/allProviders/auth_provider.dart';
import 'package:qbit/allScreens/home_page.dart';
import 'package:qbit/allWidgets/loading_view.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {

    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status){
      case Status.authenticateError:
        Fluttertoast.showToast(msg:"Sign In Fail");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Sign In Cancelled");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Sign In Successful");
        break;
      default:
        break;
    }
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Image.asset(
              "images/back.png"
            ),
          ),
          const SizedBox(height: 20.0),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GestureDetector(
              onTap: () async{
                final navigator = Navigator.of(context);
                bool isSuccess = await authProvider.handleSignIn();
                if(isSuccess){
                  navigator.pushReplacement(MaterialPageRoute(builder: (context)=>const HomePage()));
                }
              },
              child: Image.asset(
                "images/google_login.png",
              ),
            ),
          ),
          Positioned(
            child: authProvider.status == Status.authenticating ? const LoadingView():const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

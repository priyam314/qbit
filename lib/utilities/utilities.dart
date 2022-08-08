import 'package:flutter/cupertino.dart';

class Utilities{
  static bool isKeyboardShowing(){
    return WidgetsBinding.instance.window.viewInsets.bottom > 0;
  }
  static closeKeyboard(BuildContext context){
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus){
      currentFocus.unfocus();
    }
  }
}
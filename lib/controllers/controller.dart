import 'package:FrogPond/models/appstate.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * this is a base controller for frogpond 
 */
class Controller extends GetxController {
  AppState state;
  SharedPreferences prefs;

  Controller(){
    SharedPreferences.getInstance().then((p)=>this.prefs=p);
    state = AppState();
  }

  void restoreState(){
    
  }
}
import 'package:flutter/material.dart';
import 'package:fp/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((p){
      p.setBool('firstrun', false);
    });

    return Center(
      child: RaisedButton(
        child: Text('TODO'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (context) => RootView(),
        )),
      )
    );
  }  
}
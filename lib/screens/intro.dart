import 'package:flutter/material.dart';
import 'package:fp/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

//this is basically a spash screen which will show on first launch
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

/*
Welcome to Frog Pond, the anonymous local thought-space of your community! Here's some quick information to get you started!
The idea is that this app is a pond, and you are a frog, and the other users are also frogs, and you hang out in the pond and croak with each other.
There are three screens: one to enter tags and a distance to filter what you see, one to view the croaks, and one to write your own croaks.
Each croak has a set of tags, which are just keywords to describe what the croak is related to. 
Croaks can also have files attached to them. 
Croaks can be commented on, and the comments can be commented on, etc. 

*/
/*
Frog Pond mobile application
Copyright (C) 2019  Thomas Grothe

This file is part of FrogPond.

FrogPond is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

FrogPond is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
*/

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
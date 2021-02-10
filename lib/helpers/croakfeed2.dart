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
along with Frog Pond.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'package:FrogPond/screens/croakdetail.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'croaklistitem.dart';

class CroakFeed extends StatefulWidget{
  final List<Map> croaks;
  
  CroakFeed(this.croaks);//this.refresh, {this.pip});

  @override
  State<StatefulWidget> createState() {
    return CroakFeedState(croaks);
  }
}

class CroakFeedState extends State<CroakFeed>{
  
  List<Map> croaks;
  List<bool> favs; //user's favorite croaks. TODO this should be tied in to the client representation of a croak
  
  

  CroakFeedState(this.croaks);
  
  @override
  Widget build(BuildContext context) {
      return ListView.builder(
        itemBuilder: (context, i) => CroakListItem(croaks[i]),
        itemCount: croaks.length,
      );
  }
  
}
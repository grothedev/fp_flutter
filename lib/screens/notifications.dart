import 'dart:convert';

import 'package:FrogPond/helpers/croakfeed.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state_container.dart';

//where user will end up after selecting a notification. actually maybe this should just be a FeedScreen
class NotificationsScreen extends StatefulWidget{

  NotificationsScreen(){
    
  }

  @override
  State<StatefulWidget> createState() {
    return NotificationsScreenState();
  }
  
}

class NotificationsScreenState extends State<NotificationsScreen>{
  StateContainerState store;
  List croaks;
  List notifyIds;

  @override
  void initState() {
    SharedPreferences.getInstance().then((p){
      notifyIds = jsonDecode(p.getString('notify_ids'));
      
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    notifyIds.forEach((i){
      //croaks.add(store..get(i));
    });
    return CroakFeed(croaks, null);
  }
}
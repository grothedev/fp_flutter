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


import 'package:FrogPond/models/croakstore.dart';
import 'package:FrogPond/models/query.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';

class AppState {

  //List<Map> feed;
  LocalCroaksStore localCroaks;
  bool hasUnread = false; //if there are croaks to which the user is subscribed and that have new replies
  bool gettingLocation = false;
  bool fetchingCroaks = false;
  int whenCroaksFetched;
  bool croaking = false;
  Query query; //specification of current croak-search query
  LocationData location;
  double lat, lon;
  bool feedOutdated = true; //has the query been modified since the last time the croaks were fetched from server?
  bool newReplies = false;
  Map<String, int> lastCroaksGet; //milliseconds since epoch since last time croaks were fetched for each p_id (0=root). String -> int to keep w/ JSON format; would be ideal to have int -> int
  FlutterLocalNotificationsPlugin notificationsPlugin;
  int notifyCheckInterval = 15; //minutes between checking for conditions which trigger notification
  bool lefthand = false; //left handed user
  bool loading = true; //is the application still loading?
  
  AppState(){
    lastCroaksGet = Map<String, int>();
    query = Query();
    feedOutdated = true;     
    localCroaks = new LocalCroaksStore();
  }
  
}
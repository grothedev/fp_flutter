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

import 'dart:io';

import 'package:flutter/material.dart';
import 'screens/notifications.dart';
import 'state_container.dart';
import 'screens/settings.dart';
import 'screens/feed.dart';
import 'screens/composecroak.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FrogPondApp extends StatelessWidget {

  FrogPondApp();

  @override
  Widget build(BuildContext context) {
    bool intro = !File('databases/fp.db').existsSync();
    print('db found? ' + intro.toString());
    
    return MaterialApp(
      title: 'FrogPond',
      theme: ThemeData(
        primarySwatch: Colors.green,
        accentColor: Colors.green,
        backgroundColor: Color(0xFFEDEDED),
        textTheme: TextTheme(
          title: TextStyle(
            fontSize: 18
          ),
          body1: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Colors.black
          ),
          body2: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500
          ),
          subhead: TextStyle(
            fontSize: 14,
          ),
          subtitle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            
          ),
          caption: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            letterSpacing: .3
          ),
          display4: TextStyle(
            fontFamily: 'Deja Vu',
            fontSize: 9,
            color: Color(0xFF000000),
            fontWeight: FontWeight.w400,
            letterSpacing: .4,
          ),
          headline: TextStyle(
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          )
        ),
        
      ),
      
      home: RootView(),
      initialRoute: '/',
      routes:{
        '/feed': (context) => RootView(),
        '/settings': (context) => RootView(tab: 1),
        '/compose': (context) => RootView(tab: 2),
        '/notifications': (context) => NotificationsScreen(),
      },
    );
  }
}

//APP START
/*
  things that need to happen when the app launches:
    set up sqlite stuff and check if database exists
    check if it has been ran before (sqlite flag). if so, restore preferences (tags, radius)
    check last feed update time. if passed timeout, redownload some croaks, with updated location
    check if user has made any posts. if so and there are responses, notify

*/

class RootView extends StatefulWidget{
  int tab;
  
  @override
  RootState createState() => new RootState();

  RootView({this.tab});
}
class RootState extends State<RootView> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin<RootView>{
  
  TabController controller;
  StateContainerState store;

  @override
  void initState(){
    super.initState();
    controller = new TabController(length: 3, vsync: this);
    if (widget.tab != null){
      controller.index = widget.tab;
    }
    print("INIT ROOT STATE");

    SharedPreferences.getInstance().then((p){
        if (p.getInt('last_launch') == null){
          p.setInt('last_launch', DateTime.now().millisecondsSinceEpoch);
          p.setBool('firstrun', true);
        }
        if (p.getBool('query_all') == null) p.setBool('query_all', false);
      
    });
    

  }

  @override
  void deactivate(){
    store.saveState();
    super.deactivate();
  }

  @override
  void dispose(){
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    store = StateContainer.of(context);
    
    return new Scaffold(
      /*appBar: new AppBar(
        title: new Text("FrogPond"),
      ),*/
      body: new TabBarView(
        children: <Widget>[ new FeedScreen(), new SettingsScreen(), new ComposeScreen()],
        controller: controller,
      ),
      bottomNavigationBar: new Material(
        child: new TabBar(
          tabs: <Tab>[
            new Tab(icon: new Icon(Icons.rss_feed)),
            new Tab(icon: new Icon(Icons.settings)),
            new Tab(icon: new Icon(Icons.add_box))
          ],
          controller: controller,
          labelColor: Colors.green,
        ),
        type: MaterialType.canvas
      ),

    );
  }

  @override
  bool get wantKeepAlive => true;

}


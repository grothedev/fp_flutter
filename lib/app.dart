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

import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'screens/notifications.dart';
import 'state_container.dart';
import 'screens/settings.dart';
import 'screens/feed2.dart';
import 'screens/composecroak.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utilwidg.dart' as uw;

class FrogPondApp extends StatelessWidget {

  FrogPondApp();

  @override
  Widget build(BuildContext context) {  
    
    return MaterialApp(
      title: 'FrogPond',
      theme: ThemeData(
        primarySwatch: Colors.green,
        accentColor: Colors.green,
        backgroundColor: Color(0xFFEDEDED),
        textTheme: TextTheme(
          headline2: TextStyle(
            fontSize: 22,
            color: Colors.black87,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            height: 1.5,
            decorationThickness: 1
          ),
          bodyText1: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Colors.black
          ),
          bodyText2: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.05
          ),
          subtitle1: TextStyle(
            fontSize: 10,
          ),
          subtitle2: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w300,
          ),
          caption: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            letterSpacing: .3
          ),
          headline3: TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dashed, 
            fontSize: 20, 
            letterSpacing: 2,
            color: Colors.black87
          ),
          headline4: TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.bold
          ),
          headline5: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 9,
            color: Color(0xFF000000),
            fontWeight: FontWeight.w400,
            letterSpacing: .4,
          ),
          headline6: TextStyle(
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          )
        ),
        dividerColor: Colors.black38,        
        iconTheme: IconThemeData(
          size: 14,
          color: Colors.white70,

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
    check if it has been ran before. if so, restore preferences (tags, radius)
    check last feed update time. if passed timeout, redownload some croaks, with updated location
    start background fetch process to get replies of croaks that user is subscribed to

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
    super.build(context);
    store = StateContainer.of(context);
    
    return FutureBuilder(
      future: store.restoreState(),
      builder: (BuildContext bc, AsyncSnapshot<bool> res){
        print(res.data); //for dbg to see how often this gets called
        if (!res.hasData || !res.data ){
          return Scaffold(body: uw.loadingWidget("Loading Application"));
        } else {
          return Scaffold(
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
      },
      initialData: false,
    );
  }

  @override
  bool get wantKeepAlive => true;

}


import 'package:flutter/material.dart';
import 'screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'db.dart' as db;

void main() => runApp(FrogPondApp());

class FrogPondApp extends StatelessWidget {
  //root widget of application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrogPond',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: RootView(),
      routes: {
        'croakdetail': (context) => CroakDetailScreen(),
      }
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
  @override
  RootState createState() => new RootState();
}
class RootState extends State<RootView> with SingleTickerProviderStateMixin{
  TabController controller;
  //SharedPreferences prefs; //this global variable might not be necessary

  @override
  void initState(){
    super.initState();
    controller = new TabController(length: 3, vsync: this);
    db.initDB(); //in case the db was deleted
   
    SharedPreferences.getInstance().then((p){
      //TODO set things here, get filter specs, etc.
      if (p.getInt('last_launch') == null){
        p.setInt('last_launch', DateTime.now().millisecondsSinceEpoch);
        
      }
    });

  }

  @override
  void dispose(){
    controller.dispose();
    //TODO anything need to happen here?
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("FrogPond")
      ),
      body: new TabBarView(
        children: <Widget>[new HomeScreen(), new FeedScreen(), new ComposeScreen()],
        controller: controller,
      ),
      bottomNavigationBar: new Material(
        child: new TabBar(
          tabs: <Tab>[
            new Tab(icon: new Icon(Icons.home)),
            new Tab(icon: new Icon(Icons.rss_feed)),
            new Tab(icon: new Icon(Icons.add_box))
          ],
          controller: controller,
          labelColor: Colors.green,
        ),
      ),
    );
  }
  
}


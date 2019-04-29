import 'package:flutter/material.dart';
import 'screens.dart';

void main() => runApp(FrogPondApp());

class FrogPondApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrogPond',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: RootView(),
    );
  }
}

class RootView extends StatefulWidget{
  @override
  RootState createState() => new RootState();
}
class RootState extends State<RootView> with SingleTickerProviderStateMixin{
  TabController controller;

  @override
  void initState(){
    super.initState();
    controller = new TabController(length: 3, vsync: this);
  }

  @override
  void dispose(){
    controller.dispose();
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


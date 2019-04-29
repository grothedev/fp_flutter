import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class HomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome')
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RaisedButton(
              child: Text('Feed Screen'),
              onPressed: () {Navigator.pushNamed(context, '/second');}
            ),
          ],
        )
        
      )
    );
  }
}


class FeedScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return new FeedState();
  }
}

class FeedState extends State<FeedScreen>{
  
  String api_url = 'http://grothe.ddns.net:8090/api/';
  List croaks;

  //NOTE: croaks are currently redownloaded upon every time going back to screen
  @override
  void initState(){
    super.initState();
    getCroaks();
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tha Pond')
        ),
        body: Container(
          child: feedBuilder()
        ),
           
        floatingActionButton: FloatingActionButton(
              child: new Icon(Icons.add),
              onPressed: makeCroak,
            ),
        );
        
  }

  Widget feedBuilder(){
    return new ListView.builder(
      itemCount: croaks == null ? 0 : croaks.length,
      itemBuilder: (context, i) {
        return new Container(
          child: feedItem(i),
        );
      }
    );
  }

  Widget feedItem(i){
    return new ListTile(
        title: Text(croaks[i]['content'])
      );
  }
  
  //presents UI elems to allow user to compose a new croak
  void makeCroak(){
    //TODO figure out best way to implement this
  }

  //TODO update sqlite
  Future<String> getCroaks() async {
    var res = await http.get(api_url+'croaks');
    print(res.body);

    setState((){
      croaks = json.decode(res.body);
    });
  }

}
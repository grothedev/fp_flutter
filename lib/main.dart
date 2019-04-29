import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';

void main() => runApp(FrogPondApp());

class FrogPondApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrogPond',
      /*initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/feed': (context) => FeedScreen(),
      },*/
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
    controller = new TabController(length: 2, vsync: this);
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
        children: <Widget>[new HomeScreen(), new FeedScreen()],
        controller: controller,
      ),
      bottomNavigationBar: new Material(
        child: new TabBar(
          tabs: <Tab>[
            new Tab(icon: new Icon(Icons.home)),
            new Tab(icon: new Icon(Icons.rss_feed))
          ],
          controller: controller,
          labelColor: Colors.green,
        ),
      ),
    );
  }

  
}

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
            RandomWords(),
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

//fp: FeedScreen
class RandomWordsState extends State<RandomWords>{

  final suggestions = <WordPair>[];
  final bigFont = const TextStyle(fontSize: 18.0);  
  final favs = Set<WordPair>(); //saved favorite words

  //fp: get config from sqlite, update if necessary
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        
        leading: 
          IconButton(icon: Icon(Icons.list), onPressed: pushSaved,
           ),
        
        title: Text('word pair generator'),
      ),
      
      body: buildSuggestions()
    );
    
  }

  void pushSaved(){
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context){
          final Iterable<ListTile> tiles = favs.map(
            (WordPair p){
              return ListTile(
                title: Text(
                  p.asPascalCase,
                  style: bigFont
                )
              );
            }
          );
          final List<Widget> divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          //FP: simply a custom ListView of the few screens, w/ onTap. although their might be a more standar way to deal with screen navigation
          return Scaffold(
            appBar: AppBar(
              title: Text('saved suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  Widget buildSuggestions(){
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i){
        if (i.isOdd) return Divider();
        final index = i ~/ 2;
        if (index >= suggestions.length){
          suggestions.addAll(generateWordPairs().take(10));
        }
        return buildRow(suggestions[index]);
      }
    );
  }

  Widget buildRow(WordPair wp){
    final bool saved = favs.contains(wp);
    return ListTile(
      title: Text(
        wp.asPascalCase,
        style: bigFont,
      ), 
      trailing: Icon(
        saved ? Icons.favorite : Icons.favorite_border,
        color: saved ? Colors.red : null,
      ),
      onTap: (){ //fp: up/down vote and make necessary API call, expand to see comments (go to comment screen)
        setState((){ //note: here i have to manually update state by modifying an instance variable of the current RandomWordsState
          if (saved){ 
            favs.remove(wp);
          } else{
            favs.add(wp);
          }
        });
      },
    );

  }
}

class RandomWords extends StatefulWidget{
  @override
  RandomWordsState createState() => RandomWordsState();
}

class FeedScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: Text('Tha Pond')
      ),
      body: Text(
         'here would be a list with item builder making a fancy disply for each croak'
      ),
      //FP: floating action button for croaking
    );
  }
}
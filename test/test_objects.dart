/*
  this file defines mock objects used for testing
*/

import 'package:FrogPond/models.dart';

Query query = new Query();

List<Map> croaks = [
  {
    'id': 20, 
    'created_at': '2019-08-24 22:06:41', 
    'updated_at': '2019-08-24 22:06:41', 
    'x': -93.6152362, 
    'y': 42.0391029, 
    'ip': '174.217.22.6', 
    'type': 0, 
    'content': 'test croak', 
    'fade_rate': 0.6, 
    'score': 0, 
    'p_id': null, 
    'user_id': null, 
    'replies': 0, 
    'tags': [
      {
        'id': 12, 
        'label': 'test', 
        'created_at': '2019-08-24 22:06:41', 
        'updated_at': '2019-08-24 22:06:41', 
        'refs': 1, 
        'pivot': {'croak_id': 20, 'tag_id': 12}
      }
    ], 
    'files': []
  }
];
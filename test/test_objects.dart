/*
  this file defines mock objects used for testing
*/

import 'dart:io';

import 'package:FrogPond/models.dart';

Query query = new Query();

List<Map> croaks = [
  {
    'id': 1, 
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
        'id': 1, 
        'label': 'test', 
        'created_at': '2019-08-24 22:06:41', 
        'updated_at': '2019-08-24 22:06:41', 
        'refs': 1, 
        'pivot': {'croak_id': 1, 'tag_id': 1}
      },
      {
        'id': 2, 
        'label': 'random', 
        'created_at': '2019-08-24 22:06:41', 
        'updated_at': '2019-08-24 22:06:41', 
        'refs': 1, 
        'pivot': {'croak_id': 1, 'tag_id': 2}
      },
    ], 
    'files': []
  },
  {
    'id': 2, 
    'updated_at': '2019-08-24 22:06:41', 
    'created_at': '2019-08-25 21:09:31', 
    'x': -93.6152362, 
    'y': 42.0391029, 
    'ip': '174.217.22.7',
    'content': 'test croak 2',
    'score': 0, 
    'p_id': null,  
    'replies': 0, 
    'tags': [
      {
        'id': 1, 
        'label': 'test', 
        'created_at': '2019-08-24 22:06:41', 
        'updated_at': '2019-08-24 22:06:41', 
        'refs': 1, 
        'pivot': {'croak_id': 2, 'tag_id': 1}
      }
    ], 
    'files': []
  },
  {
    'id': 4, 
    'updated_at': '2019-08-24 22:06:41', 
    'created_at': '2019-08-24 02:55:17', 
    'x': -93.6152362, 
    'y': 42.0391029, 
    'ip': '174.217.22.5', 
    'content': 'test croak 3',
    'fade_rate': 0.6, 
    'score': 0, 
    'p_id': null, 
    'user_id': null, 
    'replies': 0, 
    'tags': [
      {
        'id': 1, 
        'label': 'test', 
        'created_at': '2019-08-24 22:06:41', 
        'updated_at': '2019-08-24 22:06:41', 
        'refs': 1, 
        'pivot': {'croak_id': 4, 'tag_id': 1}
      },
      {
        'id': 2, 
        'label': 'random', 
        'created_at': '2019-08-24 22:06:41', 
        'updated_at': '2019-08-24 22:06:41', 
        'refs': 1, 
        'pivot': {'croak_id': 4, 'tag_id': 2}
      },
      {
        'id': 3, 
        'label': 'general', 
        'created_at': '2019-08-24 22:06:41', 
        'updated_at': '2019-08-24 22:06:41', 
        'refs': 1, 
        'pivot': {'croak_id': 4, 'tag_id': 3}
      },
    ], 
    'files': []
  },
];

File testFile = new File('/home/thomas/dev/fp_flutter/test/test_file.txt');

Croak croakToSubmit = new Croak(
  content: "this croak is a flutter test", 
  tags: ['test', 'flutter'], 
  type: 0, 
  pid: null, 
  lat: 0, 
  lon: 90, 
  files: [testFile]
);


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

class Croak{
  int id;
  int pid; //parent
  int uid; //user (author)
  double lat, lon;
  final String content;
  final String timestamp;
  List<String> tags; //in the future, tags might have to be more aligned with the data structure on the server
  List<File> files;
  final int score;
  final int type;

  Croak({this.id, this.pid, this.content, this.timestamp, this.score, this.lat, this.lon, this.type, this.tags, this.files}){
    List<String> ts = []; //temp list to fix duplicates
    tags.forEach((t){ 
      if (!ts.contains(t)) ts.add(t);
    });
    this.tags = ts;
  }


  Map<String, dynamic> toMap(){
    return {
      'id': id.toString(),
      'p_id': pid != null ? pid.toString() : '',
      'user_id': uid != null ? uid.toString() : '',
      'x': lon.toString(),
      'y': lat.toString(),
      'score': score.toString(),
      'content': content,
      'tags': tags.join(','),
      'timestamp': timestamp,
      'type': type.toString(),
      'files': files.toString()
    };
  }
}
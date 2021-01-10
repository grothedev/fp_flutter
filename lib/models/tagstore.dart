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

import 'dart:convert';


/*
a type of repository that handles the tags that are of concern to the user.
decided to do it this way because i wanted a few things to happen:
  - tags are saved and restored when the app is opened again
  - user can enter indivual tags of mode include or exclude and then they appear in the chip selector with the suggested tags
  - 

*/


class LocalTagsStore{
  List<dynamic> tags = [];
  //might keep two lists of tags: include and exclude, then present two filter chip scrollables

  LocalTagsStore(List<dynamic> tags){
    if (tags == null || tags.length == 0) return;
    if (tags[0] is String){
      tags.forEach((t){
        add(t, false);
      });
    } else if (tags[0] is Map){
      if (tags[0].containsKey('label') && tags[0].containsKey('mode') && tags[0].containsKey('use')){
        this.tags = List.from(tags);
      }
    } 
  }

  void set(String label, int mode){
    get(label)['mode'] = mode;
  }

  //toggles whether or not to use this tag in query
  void toggleUse(String label){
    Map t = get(label);
    t['use'] = !t['use'];
  }

  void use(String label, bool u){
    Map t = get(label);
    t['use'] = u;
  }

  Map<String, dynamic> get(String label){
    var tag = tags.firstWhere((t){ return t['label'] == label; });
    if (tag == null){
      print('tag doesnt exist');
      tag = add(label, false);
    }
    return tag;
  }

  List<String> getLabels(){
    List<String> res =  tags.map((t){ return t['label'].toString(); }).toList();
    print(res.toString());
    return res;
  }

  /**
   * get the labels of the currently active tags
   */
  List<String> getActiveTagsLabels(){ //might as well combine filtering and mapping since that's the only use case so far
    return tags.where((t){ return t['use']; }).map((t){ return t['label'].toString(); }).toList();
  }

  dynamic add(dynamic label, bool use){
    if (label is String){
      if (label=='') return null; 
      if ( tags.where((t){ return t['label'].toLowerCase() == label.toLowerCase(); }).isNotEmpty ) return null;
      print('lts receiving string: ' + label);
      this.tags.add({
        'label': label,
        'mode': 0, //0=include, 1=exclude; using int because there might be more modes in future
        'use': use,
      });
      return this.tags.last;
    } else if (label is List<String>){
      print('lts receiving list: ' + label.toString());
      List added = [];
      label.forEach((l){
        added.add(add(l, use));
      });
      print('local tags store: ' + this.tags.toString());  
      return added;
    } else return null;
  }

  void empty(){
    tags.clear();
    tags = [];
  }

  //returns a new LTS from the string representation stored in shared prefs
  static LocalTagsStore fromJSON(String str){
    if (str.length == 0) return new LocalTagsStore(null);
    List tags = List.from(jsonDecode(str));
    return new LocalTagsStore(tags);
  }

  //returns string of json representation of this LocalTagsStore
  String toJSON(){
    return jsonEncode(tags);
  }


  String toString(){
    return tags.toString();
  }
}
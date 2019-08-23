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
along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
*/


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fp/state_container.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util.dart' as util;
import '../models.dart';

//"local" as in stored on the user's device and of concern to the user
class LocalTags extends StatefulWidget{
  //final LocationData location;
  //final List tags;
  LocalTagsStore tags;
  final Function onChipSelected; //TODO: passed in function no longer necessary since this widget is coupled with a LocalTagsStore, so it can update it directly

  LocalTags(this.tags, this.onChipSelected);

  @override
  State<StatefulWidget> createState() {
    return LocalTagsState(tags);
  }
}

class LocalTagsState extends State<LocalTags> with AutomaticKeepAliveClientMixin<LocalTags>{
  List chips;
  int n = 16; //# tags to retreive
  bool loading = true;
  SharedPreferences prefs;
  //List tags; //suggested tags retrieved from server
  LocalTagsStore tagStore;
  //LocationData location;
  List<FilterChip> tagChips; //seeing if i can bypass the custom widget class i made previously, which might be too much unnecessary complexity


  LocalTagsState(this.tagStore);

  @override
  void initState() {
    super.initState();
    chips = <Widget>[];
    tagChips = <FilterChip>[];    
  }

  @override
  Widget build(BuildContext context) {
    if (tagStore.tags == null) return Text('no tags');

    for (var i = 0; i < tagStore.tags.length; i++){
      Map t = tagStore.tags[i];
      chips.add(TagChip(tag: t, prefs: prefs));  
      tagChips.add(
        FilterChip(
          label: Text(t['label']),
          selected: t['use'],
          padding: EdgeInsets.all(4),
          labelPadding: EdgeInsets.all(2),
          onSelected: ((v){
            setState((){
              t['use'] = v;
            });
          }),
        )
      );
    }
    
    return Flex(
      direction: Axis.vertical,
      children: [
        //Text('Here are some popular tags in your area, pick some that are of interest to you', style: Theme.of(context).textTheme.subhead,), //perhaps the value of this title should be decoupled from the widget
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            children: this.chips,
            //children: this.tagChips,
            spacing: 8,
          ),
        )
      ]
    );
  }

  @override
  bool get wantKeepAlive => true;
  
}

class TagChip extends StatefulWidget{

  final Map tag;
  final SharedPreferences prefs;
  final Function onSelected;

  TagChip({Key key, this.tag, this.prefs, this.onSelected}): super(key: key);

  @override
  State<StatefulWidget> createState(){
    return TagChipState();
  }
}


class TagChipState extends State<TagChip>{

  bool sel = false;
  StateContainerState store; //i think this is pretty close to the redux concept of a "store". thought var name "stateContainer" was too long

  @override
  Widget build(BuildContext context) {
      store = StateContainer.of(context);
      Map t = widget.tag;

      return FilterChip(
        label: Text(t['label']),
        selected: sel,
        padding: EdgeInsets.all(4),
        labelPadding: EdgeInsets.all(2),
        onSelected: ((v){
          setState((){
            sel = v;
          });
          store.toggleUseTag(t['label']);
        }),
      );
  }
  
}
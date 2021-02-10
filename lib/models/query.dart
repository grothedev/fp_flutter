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

import 'package:FrogPond/models/tagstore.dart';

import '../consts.dart';

class Query{
  LocalTagsStore localTags;
  bool tagsIncludeAll; //get croaks which are associated with all (true) or some (false) of selected tags
  int radius;
  int distUnit;
  //TODO add keywords

  Query(){
    localTags = LocalTagsStore();
    tagsIncludeAll = false;
    radius = 0;
    distUnit = KM;
  }

  @override
  bool operator ==(Object other) {
    Query o;
    if (other is Query){
      o = other;
    } else { return false; }
    
    return radius == o.radius && tagsIncludeAll == o.tagsIncludeAll && 
              localTags.toJSON() == o.localTags.toJSON();
  }
}
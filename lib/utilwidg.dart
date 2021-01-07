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


//this is for functions which would otherwise go into util.dart, but do not because they deal with widgets and UI stuff (usually are passed a widget or state as a parameter)
import 'package:flutter/material.dart';

//presents file picker interface.
Future getFile(state) async{ //currently supports one file; will provide multiple files in future if necessary
  //var f = await FilePicker.getFile(type: FileType.ANY);
  /*state.setState((){
    state.file = f; //this is bad because getFile() the passed in state HAS to have 'file' var, and this getFile() has to know that
  });*/
}

//actually realized i over-engineered this (in the case of file picker), so i will not use it, but will leave the file here for historical purposes and incase it becomes useful later


/**
 * @return loading screen for fetching data
 */
Widget loadingWidget(String msg){
  return Column(
      children: [
        Text(msg + "..."),
        Center(
            child: Container(
              width: 120, 
              height: 120,
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(
                      value: null,
                      semanticsLabel: 'Retreiving Croaks...',
                      semanticsValue: 'Retreiving Croaks...',
                  ),
              )
          ),
      ]
    );
}
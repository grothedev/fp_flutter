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


import 'package:FrogPond/screens/croakdetail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../state_container.dart';

import '../util.dart' as util;

/*
  * probably obsolete. just including it on bottom of croakdetail screen
//a form to overlay the main UI to make and submit croaks.
  was gonna use this for both replies and root croaks, but decided to keep ComposeDialog and ComposeScreen separate,
  because ComposeScreen may as well keep its "fuller" design
*/
class ComposeCroakDialog extends Dialog{
  
  final contentController = TextEditingController();
  static final fk = GlobalKey<FormState>();// form key
  final Map parent; //croak replying to
  bool anon = true;
  StateContainerState store;
  bool loading = false;
  Function onSubmitReply;

  ComposeCroakDialog(this.parent, this.onSubmitReply);
  
  @override
  Widget build(BuildContext context){
    store = StateContainer.of(context);
    if (loading) {
      return SimpleDialog(
        contentPadding: EdgeInsets.all(6),
        titlePadding: EdgeInsets.all(4),
        title: Text('Croakin...')
      );
    }
    return SimpleDialog( 
              contentPadding: EdgeInsets.all(6),
              titlePadding: EdgeInsets.all(4),
              title: (this.parent != null) ? Text('Reply') : Text('Croak'),
              children: [
                Form(

                  key: fk,
                  child: Column(
                    //direction: Axis.vertical,
                    children: [
                      TextFormField(
                        
                        controller: contentController,
                        /*validator: (value){
                            if (value.isEmpty) return 'Enter some text';
                        },*/
                        decoration: InputDecoration(
                          icon: Icon(Icons.message),
                          labelText: 'Reply',

                        ),
                        maxLines: 3,
                        minLines: 1,
                        autofocus: false,
                        autovalidate: false,
                        
                      ),
                     /*RaisedButton(
                        onPressed: () => { 
                              FilePicker.getFile(type: FileType.ANY).then((f){
                                f.stat().then((s){
                                  //wat do here cause can't set state
                                  print('reply attach file ' + f.path + ': ' + s.size.toString());
                                });
                            }) },
                        child: Text('Attach File')
                      ),*/
                        //force anon for phase 1
                        /*
                        CheckboxListTile(
                          value: this.anon,
                          title: Text('anon'),
                          onChanged: (v){
                            anon = !anon;
                          },

                        ),
                        */
                      
                        RaisedButton(
                          onPressed: (){
                            if (fk.currentState.validate()){
                              //Scaffold.of(context).showSnackBar(SnackBar(content: Text('Replying...')));
                              //Croak r = Croak();
                              print('replying ' + parent.toString());
                              loading = true;
                              store.needsUpdate();
                              util.submitReply(parent['id'], contentController.text, parent['tags'], true, store.state.location).then((s){
                                if (s){
                                  Navigator.pop(context);
                                  //StateContainer.of(context).updateReplies();
                                  onSubmitReply();
                                } else {
                                  Scaffold.of(context).showSnackBar(SnackBar(content: Text('Reply Failed')));
                                }
                              }); //TODO add functionality to add additional tags?
                            } else print('invalid');
                          },
                          child: Text("Reply"),
                          
                        )
                    ]
                  ),
                ),
                
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)), 
              ),
              

            ) ;
  }
}
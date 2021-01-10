import 'dart:convert';

import 'package:FrogPond/consts.dart';
import 'package:FrogPond/controllers/controller.dart';
import 'package:FrogPond/models/croakstore.dart';
import 'package:FrogPond/util.dart' as util;

class CroakController extends Controller {

  LocalCroaksStore croakStore;

  CroakController(){
    croakStore = state.localCroaks;
  }

  Future<List> getCroaks(bool forceAPI, int pid) async {
    List result;
    if (forceAPI || state.lastCroaksGet[pid.toString()] == null || DateTime.now().millisecondsSinceEpoch - state.lastCroaksGet[pid.toString()] > CROAKS_GET_TIMEOUT){
      if (pid == 0){
        await util.getCroaks(state.query, state.location).then((List croaks){
          if (croaks == null) return;
          croakStore.hideAll();
          croakStore.add(croaks, true, false);
          croaks.forEach((c){
            if (c['p_id'] == null) c['p_id'] = 0;
            state.lastCroaksGet[c['p_id'].toString()] = DateTime.now().millisecondsSinceEpoch;
          });
          prefs.setString('local_croaks', state.localCroaks.toJSON());
          prefs.setString('last_croaks_get', jsonEncode(state.lastCroaksGet));
          result = croaks;
        }).timeout(Duration(seconds: 8), onTimeout: ()=>null);
      } else {
        await util.getReplies(pid).then((replies){
          croakStore.add(replies, false, false);
          state.lastCroaksGet[replies[0]['p_id']] = DateTime.now().millisecondsSinceEpoch;
          prefs.setString('local_croaks', state.localCroaks.toJSON());
          prefs.setString('last_croaks_get', jsonEncode(state.lastCroaksGet));
          result = replies;
        }).timeout(Duration(seconds: 8), onTimeout: ()=>null);
      }
    } else {
      result = croakStore.ofQuery(state.query);
    }
    return result;
  }

  //unsubscribe from all croaks
  void unsubAll(){
    croakStore.getListeningIDs().forEach((l){
      croakStore.unsub(l);
    });
    prefs.setString('local_croaks', croakStore.toJSON());
  }

  void submitCroak(Map croak){
    state.croaking = false;
    
    if (croak != null){
      croakStore.add(croak, false, true);
      prefs.setString('local_croaks', croakStore.toJSON());
    }
  }

  //toggle if background process will check for replies of given croak to notify user
  void toggleSubscribe(int id){
    croakStore.toggleSubscribe(id);  
    
    prefs.setString('local_croaks', croakStore.toJSON());
    print(croakStore.get(id).toString());
  }
}
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
    if (forceAPI || state.lastCroaksGet['0'] == null || DateTime.now().millisecondsSinceEpoch - state.lastCroaksGet['0'] > CROAKS_GET_TIMEOUT){
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
        }).timeout(Duration(seconds: 8), onTimeout: ()=>null);
      } else {
        await util.getReplies(pid).then((replies){
          croakStore.add(replies, false, false);
          state.lastCroaksGet[replies[0]['p_id']] = DateTime.now().millisecondsSinceEpoch;
          prefs.setString('local_croaks', state.localCroaks.toJSON());
          prefs.setString('last_croaks_get', jsonEncode(state.lastCroaksGet));
        }).timeout(Duration(seconds: 8), onTimeout: ()=>null);
      }
    }
    return croakStore.ofQuery(state.query);
  }
}
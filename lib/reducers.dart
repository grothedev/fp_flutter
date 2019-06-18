import 'models.dart';
import 'util.dart' as util;

enum Actions {requestCroaks, receiveCroaks }

AppState rootReducer(AppState state, dynamic action) {
  if (action ==  Actions.requestCroaks){
    util.getCroaks();
    state.fetchingCroaks = true;
    return state;
  } else if (action.type == Actions.receiveCroaks){
    state.feed = action.feed;
    state.fetchingCroaks = false;
  } else {
    return state;
  }
      
  
}
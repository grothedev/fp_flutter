import 'models.dart';
import 'api.dart' as api;


//NOTE: util might not be the best name
//these are helper functions to pass data to the api calls so that you don't have to worry about constructing the croak maps in event handlers

bool submitReply(int p_id, String content, String tags, anon){ //TODO support user account posting 
  Croak c = new Croak(content: content, timestamp: new DateTime.now().toString() , score: 0, pid: p_id);
  return postCroak(c.toMap());
}

bool submitCroak(String croak, String tags, anon){
  Croak c = new Croak(content: croak, timestamp: new DateTime.now().toString() , score: 0, tags: tags.split(' '), type: 0, pid: 0);
  return postCroak(c.toMap());
}

bool postCroak(Map c){
  api.postCroak(c).then((r){
    if (r == '0'){
      return true;
    }
    return false;
  });
}

//TODO make functions for varying croak type inputs
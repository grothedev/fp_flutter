//TODO is sqlite caching as clean as it can be?
 
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'models.dart';

//String api_url = 'http://grothe.ddns.net:8090/api/';
String api_url = 'http://192.168.1.7:8090/api/'; //tmp while at cabin

//tl = taglist ; at = should get croaks with all(true) or some(false) given tags ; p_id = parent id
Future<List> getCroaks(double x, double y, int p_id, List<String> tl, bool at) async {
  var reqURL = api_url+'croaks?';
  if (tl != null && tl.length > 0){
    reqURL += 'tags=' + tl.join(',') + '&'; 
  }
  if (p_id > 0){
    reqURL += 'p_id=' + p_id.toString() + '&';
  }
  if (at){
    reqURL += 'mode=1&';
  }
  print('api.getCroaks reqURL: ' + reqURL);

  var res = await http.get(reqURL); //TODO handle location

  //print('api.getCroaks response body: '+ res.body);

  return json.decode(res.body);

}

Future<String> postCroak(Map<String, dynamic> req) async {
  
  print('post croak: ' + req.toString());

  var res = await http.post(api_url+'croaks', body: req);
  return res.body;
}

//get most referenced n tags
Future<List> getTags(int n) async{
  var res = await http.get(api_url+'tags?n='+n.toString());
  return json.decode(res.body);
}
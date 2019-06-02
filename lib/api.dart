//TODO is sqlite caching as clean as it can be?
 
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'models.dart';

String api_url = 'http://grothe.ddns.net:8090/api/';

Future<List> getCroaks(double x, double y, int p_id, List<String> tl) async {
  var reqURL = api_url+'croaks?';
  if (tl != null && tl.length > 0){
    reqURL += 'tags=' + tl.join(',') + '&'; 
  }
  if (p_id > 0){
    reqURL += 'p_id=' + p_id.toString() + '&';
  }

  var res = await http.get(reqURL); //TODO handle location

  print(res.body);

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
//TODO is sqlite caching as clean as it can be?
 
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'models.dart';

String api_url = 'http://grothe.ddns.net:8090/api/';

Future<List> getCroaks() async {
  var res = await http.get(api_url+'croaks');
  print(res.body);

  return json.decode(res.body);

}

Future<String> postCroak(Map<String, dynamic> req) async {
  
  var res = await http.post(api_url+'croaks', body: req).then((r){print(r.body);});

  return json.decode(res.body);
}
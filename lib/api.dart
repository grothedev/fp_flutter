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
 
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

//String host = 'grothe.ddns.net';
//String host = '192.168.1.18'; //tmp local
String host = '173.22.78.225';
int port = 8090;
String api_url = 'http://' + host + ':' + port.toString() + '/api/'; 

//tl = taglist ; at = should get croaks with all(true) or some(false) given tags ; p_id = parent id
Future<List> getCroaks(double x, double y, dynamic p_id, List<String> tl, bool at, int rad) async {
  var reqURL = api_url+'croaks?';
  if (tl != null && tl.length > 0){
    reqURL += 'tags=' + tl.join(',') + '&'; 
  }
  if (p_id != null){ 
    if (p_id is int) reqURL += 'p_id=' + p_id.toString() + '&';
    else if (p_id is List) reqURL += 'p_id=' + p_id.join(',') + '&';
  }
  if (at){
    reqURL += 'mode=1&';
  }
  if (rad != null){
    rad == 0 ? reqURL += 'x='+x.toString() + '&y='+y.toString() + '&' 
              : reqURL += 'x='+x.toString() + '&y='+y.toString() + '&radius='+rad.toString() + '&';
  }
  print('api.getCroaks reqURL: ' + reqURL);

  var res = await http.get(reqURL).catchError((e){ print('http get failed: ' + e.toString()); } );
  if ( !(res is http.Response) ) {
    print('api: response retrieval error: ' + res.toString());
    return null;
  }
  return json.decode(res.body);
}

//takes file separately because Croak.toMap() had to give string representations of all of its instance vars
Future<String> postCroak(Map<String, dynamic> req, File f) async {
  //print(req.toString());
  //print(f.toString());

  if (f != null){
    req.addAll({'f': [ MultipartFile.fromBytes(f.readAsBytesSync(), filename: basename(f.path))]  });
    //req.addAll({'f': [ MultipartFile.fromFile(f.path, filename: basename(f.path))] });
    FormData fd = FormData.fromMap(req);
    
    print('api post croak: ' + fd.files.toString());
    print(fd.fields.toString() + ',  ' + req.toString());
    Response res =  await Dio().post(api_url+'croaks', data: fd, options: Options(contentType: "application/x-www-form-urlencoded", )).catchError((e){
      print('Dio error: ' + e.toString());
      return e.toString();
    });
    return jsonEncode(res.data);

  } else {
    print('api post croak: ' + req.toString());
    req.forEach((k, v) {
      print(k + ': ' +v.toString());
    });
    var res = await http.Client().post(api_url+'croaks', body: req).catchError((e){
      print('api post failed: ' + e.toString());
    });
    if (res == null) return null;
    print('rest response: ' + res.body);
    return res.body;
  }
}

//get most referenced n tags
Future<List> getTags(int n, double lat, double lon) async{
  if (lat == null) lat = 0;
  if (lon == null) lon = 0;
  //var res = await http.get(api_url+'tags?n='+n.toString()+'&lat='+lat.toString()+'&lon='+lon.toString()).catchError((e){return null;});
  var res = await http.get(api_url+'tags?n='+n.toString()).catchError((e){return null;});
  print('api request: ' + api_url+'tags?n='+n.toString() );
  if (res == null) return null;
  print('api response: ' + res.body.toString());
  return json.decode(res.body);
}

Future<String> getMOTD() async{
  var res = await http.get(api_url+'motd').catchError((e){ return 'MOTD: Error'; });
  return res.body;
}

Future<String> reportCroak(int id) async {
  var res = await http.get(api_url+'croaks/report?croak_id=' + id.toString());
  return res.body;
}

Future<String> postVote(Map<String, dynamic> req) async{
  var res = await http.Client().post(api_url+'votes', body: req);
  return res.body.toString();
}

//is the server reachable?
Future<bool> testConnection() async{
  http.get(api_url).then((r){
    print(r.toString());
    return true;
  }).catchError((e){
    print('API test error: ' + e.toString());
    return false;
  });
  
}
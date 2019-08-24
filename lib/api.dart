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
along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
*/

//TODO is sqlite caching as clean as it can be?
 
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert';
import 'models.dart';
import 'package:dio/dio.dart';

//String host = 'grothe.ddns.net';
//String host = '192.168.1.5'; //tmp local
String host = '173.22.78.225';
//String host = '192.168.1.5'; //tmp local
int port = 8090;
String api_url = 'http://' + host + ':' + port.toString() + '/api/'; 

//tl = taglist ; at = should get croaks with all(true) or some(false) given tags ; p_id = parent id
Future<List> getCroaks(double x, double y, int p_id, List<String> tl, bool at, int rad) async {
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
  if (rad != null && rad != 0){
    reqURL += 'x='+x.toString() + '&y='+y.toString() + '&radius='+rad.toString() + '&';
  }
  print('api.getCroaks reqURL: ' + reqURL);

  var res = await http.get(reqURL).catchError((e){ print('http get failed: ' + e.toString()); } ); //TODO handle location
  if ( !(res is http.Response) ) {
    print('api: response retrieval error: ' + res.toString());
    return null;
  }
  //print('api.getCroaks response body: '+ res.body);
  print('api response: ' + res.body);
  return json.decode(res.body);

}

//takes file separately because Croak.toMap() had to give string representations of all of its instance vars
Future<String> postCroak(Map<String, dynamic> req, File f) async {
  print(req.toString());

  if (f != null){
    req.addAll({'f[]': [ new UploadFileInfo(f, basename(f.path))]  });
    FormData fd = FormData.from(req);
    
    print('api post croak: ' + fd.toString());
    Response res =  await Dio().post(api_url+'croaks', data: fd).catchError((e){
      print('Dio error: ' + e.toString());
    });
    return res.data;

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

Future<String> postVote(Map<String, dynamic> req) async{
  var res = await http.Client().post(api_url+'votes', body: req);
  return res.body.toString();
}
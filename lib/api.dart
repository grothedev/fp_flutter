//TODO is sqlite caching as clean as it can be?
 
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import 'dart:convert';
import 'models.dart';

//String host = 'grothe.ddns.net';
String host = '192.168.1.5'; //tmp while at cabin
int port = 8090;
String api_url = 'http://' + host + ':' + port.toString() + '/api/'; 


//tl = taglist ; at = should get croaks with all(true) or some(false) given tags ; p_id = parent id
Future<List> getCroaks(double x, double y, int p_id, List<String> tl, bool at) async {
  var reqURL = api_url+'croaks?';
  if (tl != null && tl.length > 0){
    reqURL += 'tags=' + tl.join(',') + '&'; 
  }
  if (p_id > 0){
    reqURL += 'p_id=' + p_id.toString() + '&';
  }
  if (at != null && at){
    reqURL += 'mode=1&';
  }
  print('api.getCroaks reqURL: ' + reqURL);

  var res = await http.get(reqURL); //TODO handle location

  //print('api.getCroaks response body: '+ res.body);

  return json.decode(res.body);

}

//takes file separately because Croak.toMap() had to give string representations of all of its instance vars
Future<String> postCroak(Map<String, dynamic> req, File f) async {
  
  if (f != null){
    //TODO 
    var mr = new http.MultipartRequest('POST', Uri.parse(api_url));
    mr.fields['tags'] = req['tags'];
    mr.fields['type'] = req['type'];
    mr.fields['content'] = req['content'];
    mr.fields['lat'] = req['lat'];
    mr.fields['lon'] = req['lon'];
    mr.fields['p_id'] = req['pid'];
    File f = req['files'][0];

    var mf = await http.MultipartFile.fromPath('f', f.path, contentType: new MediaType('multipart', 'mixed'));
    mr.files.add(mf); 

    mr.send().then((res){
      print(res);
      return res;
    });
  } else {
    print('post croak: ' + req.toString());

    var res = await http.post(api_url+'croaks', body: req);
    return res.body;
  }

  

  
}

//get most referenced n tags
Future<List> getTags(int n, double lat, double lon) async{
  if (lat == null) lat = 0; //TODO make a request option which bypasses location
  if (lon == null) lon = 0;
  var res = await http.get(api_url+'tags?n='+n.toString()+'&lat='+lat.toString()+'&lon='+lon.toString());
  return json.decode(res.body);
}
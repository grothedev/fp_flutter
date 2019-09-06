/*
Future<List> getCroaks(Query query, int lastUpdated, LocationData location)
  should return a list of the croaks, the json array from api response
  if croaks have recently been retrieved (less than CROAKS_GET_TIMEOUT ms ago), then get from api and save the new ones to local db
    should call queryCroaks() and db.saveCroaks()
  else get the ones which have been saved to local db
    should call db.loadCroaks()

Future<List> queryCroaks(loc, tagList, qa, radius)
  should return a list of croaks (json array from api response) sorted by created_at
  should call api.getCroaks()
*/

import '../lib/models.dart';
import 'package:location/location.dart';
import 'package:test/test.dart';
import '../lib/util.dart' as util;
import 'test_objects.dart' as objs;

void main(){
  test('getCroaks() with not fetched recently', () async {
    Query q = new Query();
    LocationData loc;


    List croaks = await util.getCroaks(q, null, loc);

    expect(croaks.length > 0, true);
  });
}
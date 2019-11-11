/*
  Future<String> postCroak(Map<String, dynamic> req, File f)
    returns the server response of POST croaks with the given data, or Dio error
*/

import 'package:http/http.dart';
import 'package:test/test.dart';
import 'test_objects.dart';
import 'package:FrogPond/api.dart' as api;

void main(){
  test('postCroak', () async {

    String response = await api.postCroak(croakToSubmit.toMap(), testFile);
    print(response);

    expect(response != '-1', true);
  });
}
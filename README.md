FrogPond mobile application, made with flutter. https://flutter.dev/


4/30:  flutter is actually pretty awesome, so using it now.



TODO:
* croak detail screen
	- fix spacing
	- implement threaded comments
* compose croak screen
	- clean up UI
	- actually attach the files
* verify the following features of API are working: popular tags, get by keywords, get by location,
* notifications
* about page
* put entire roadmap and feature plans and vision here
* URLS to simple display rather than API


SharedPreferences:
  * last_croaks_get (int) : ms since croaks were last retreived
  * lat (double) : latitude of user
  * lon (double) : longitude of user
  * query_kwdAll (bool) : get croaks by contain all(1) or some(0) of given keywords (tags)

uses some packages:
  file picker: https://pub.dev/packages/file_picker
  toast: https://pub.dev/packages/toast


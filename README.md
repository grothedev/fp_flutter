FrogPond mobile application, made with flutter. https://flutter.dev/


4/30:  flutter is actually pretty awesome, so using it now.


some util functions should probably go into StateController

TODO:
* fix the async timing issues
* refresh feed after change tags
    - make croakfeed a consumer, and the croaks and tags a changenotifier
* sug tags for compose croak
* automatically update comments upon submit comment
* timeout for feed loading
* intro "tutorial" and better homescreen text
* better looking title/subtitle situation
* word wrap for attached file
* croak detail screen
	- fix spacing
	- implement threaded comments (or keep screen stack?)
* compose croak screen
	- clean up UI
	- actually attach the files
* reply form on croak detail screen or dialog from floating action button?
* keep home screen settings state on tab view switch
* verify the following features of API are working: get by keywords, get by location,
* notifications
* about page
* put entire roadmap and feature plans and vision here
* URLS to simple display rather than API

SharedPreferences:
  * last_croaks_get (int) : ms since croaks were last retreived
  * lat (double) : latitude of user
  * lon (double) : longitude of user
  * query_all (bool) : get croaks by contain all(1) or some(0) of given tags
  * tags (List<String>) : tags to query for
  * needsUpdate (bool) : does the main feed need to be updated?
uses some packages:
  file picker: https://pub.dev/packages/file_picker
  toast: https://pub.dev/packages/toast


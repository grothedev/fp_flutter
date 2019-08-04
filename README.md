FrogPond mobile application, made with flutter. https://flutter.dev/

TODO:
* fix db stuff
* intro "tutorial" 
* better homescreen text
* about page (feedback, source, )
* UI stuff 
  - show video or image or audio player based on file type. 
  - fix feed list formatting
  - load screen upon submit croak
  - feed screen when no croaks in area: add appbar and message
  - pull to refresh
  - ripple-like watermarks??
* notifications
* put entire roadmap and feature plans and vision here
* post-initial-release features
  - voting
  - different croak types (poll, resource bank, plant, tool library, event)
  - going to need to devise a better way of storing and managing croaks to improve performance when there might be thousands of croaks 
  - get by keywords on API

SharedPreferences:
  * last_croaks_get (int) : ms since croaks were last retreived
  * lat (double) : latitude of user
  * lon (double) : longitude of user
  * exclusive (bool) : get croaks by contain all(1) or some(0) of given tags
  * tags (List<String>) : tags to query for
  * radius (int) : geographical radius of query (km)
  * dist_unit (int) : 0 = kilometers ; 1 = miles
  * needs_update (bool) : does the main feed need to be updated?
  * firstrun (bool) : if this is the first time the app has been run
uses some packages:
  file picker: https://pub.dev/packages/file_picker
  toast: https://pub.dev/packages/toast


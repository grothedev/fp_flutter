FrogPond mobile application, made with flutter. https://flutter.dev/

TODO:
* fix persistent query tags
* save sort preferences
* save prefs in statecontainer deactivate method
* implement data analysis (show locations of croaks w/ tags etc. )
* tutorial mode?
* UI stuff
  - show video or audio player based on file type.
  - ripple-like watermarks??
  - icons and animation
    - submit croak (croaking)
    - fetch croaks (ripples)
    - app icon
    -
* attach file to reply
* tag exclusion
* remove unused stuff like the old tag list
* button to show complete list of tags (also get more popular tags)
* notifications
* post-initial-release features
  - identify commenters or just OP?
  - different croak types (poll, resource bank, plant, tool library, event)
  - get by keywords on API
  - possibly take picture from app https://flutter.dev/docs/cookbook/plugins/picture-using-camera
      https://pub.dev/packages/camera
* implement usage stats for API

SharedPreferences:
  * last_croaks_get (int) : ms since croaks were last retreived
  * lat (double) : latitude of user
  * lon (double) : longitude of user
  * exclusive (bool) : get croaks by contain all(1) or some(0) of given tags
  * tags (List<String>) : tags to query for 
  * radius (int) : geographical radius of query (km)
  * dist_unit (int) : 0 = kilometers ; 1 = miles
  * needs_update (bool) : do some UI elements need to be updated?
  * feed_outdated (bool) : do main feed croaks need to be fetched again?
  * ran_before (bool) : if the app has been run on the device before
  * notify_check_interval (int) : minutes between checking for conditions which send device notification 
  * feed_croaks (string) : a json string representing all of the croaks of the most recent feed the user was presented with
  * local_tags (string) : a json string representing the LocalTagsStore
SQLite DB:
    * croaks table is same as server except for one additional column, "listening" flag which tells if user wants to receive notifications for when that croak gets a new comment
FrogPond mobile application, made with flutter. https://flutter.dev/

TODO:
* fix db stuff (this is not necessary for the initial release, but will be once there are > 20 users)
    - when there are a lot of croaks, you certainly don't want so many people making requests all the time and repeatedly downloading so much data.
* save sort preferences
* implement data analysis (show locations of croaks w/ tags etc. )
* reply submit loading
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
* copy croak content
* button to show complete list of tags (also get more popular tags)
* notifications
* post-initial-release features
  - voting
  - identify commenters or just OP
  - different croak types (poll, resource bank, plant, tool library, event)
  - going to need to devise a better way of storing and managing croaks to improve performance when there might be thousands
   of croaks
  - get by keywords on API
  - possibly take picture from app https://flutter.dev/docs/cookbook/plugins/picture-using-camera
      https://pub.dev/packages/camera
* make a test class with test data structures etc.
* implement usage stats for API

SharedPreferences:
  * last_croaks_get (int) : ms since croaks were last retreived
  * lat (double) : latitude of user
  * lon (double) : longitude of user
  * exclusive (bool) : get croaks by contain all(1) or some(0) of given tags
  * tags (List<String>) : tags to query for
  * radius (int) : geographical radius of query (km)
  * dist_unit (int) : 0 = kilometers ; 1 = miles
  * needs_update (bool) : does the main feed need to be updated?
  * ran_before (bool) : if the app has been run on the device before
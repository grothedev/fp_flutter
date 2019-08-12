FrogPond mobile application, made with flutter. https://flutter.dev/

TODO:
* fix db stuff (this is not necessary for the initial release, but will be once there are > 20 users)
    - when there are a lot of croaks, you certainly don't want so many people making requests all the time and repeatedly downloading so much data. 
* save sort preferences
* implement data analysis (show locations of croaks w/ tags etc. )
* intro "tutorial" 
* better homescreen text
  - link to vision. make clear that it is a platform which is supposed to evolve naturally
* about page (feedback, source, )
* UI stuff 
  - show video or audio player based on file type. 
  - ripple-like watermarks??
  - change wording: score to popularity?
  - icons and animation
    - submit croak (croaking)
    - fetch croaks (ripples)
    - app icon
    -   
* attach file to reply
* server stuff
  - monitor bandwidth
  - log each request
  - 
* notifications
* post-initial-release features
  - voting
  - different croak types (poll, resource bank, plant, tool library, event)
  - going to need to devise a better way of storing and managing croaks to improve performance when there might be thousands of croaks 
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
  * firstrun (bool) : if this is the first time the app has been run
uses some packages:
  file picker: https://pub.dev/packages/file_picker
  toast: https://pub.dev/packages/toast

Development Timeline:
  tues:
    fix server file upload issue
    verify croak compose file upload
    start working on graphics
  wed:
    set up server in room
    finalize description and all meta-info
    continue graphics
  thurs:
    release an open beta? post on isu subreddit
    continue graphics

  Initial release by August 20th (optimistic), latest 24th
  have docker and server hosting ready by 12th
  release beta test by end of tues:
    
  keep tackling as many tasks as possible everyday this week
  write the about page and stuff
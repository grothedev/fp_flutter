FrogPond mobile application, made with flutter. https://flutter.dev/

TODO:
* fix db stuff
* save sort preferences
* intro "tutorial" 
* better homescreen text
* about page (feedback, source, )
* UI stuff 
  - more hints (no spaces in tags, etc.)
  - show video or image or audio player based on file type. 
  - fix feed list formatting
  - time format
  - load screen upon submit croak
  - ripple-like watermarks??
  - change wording: score to popularity?
* attach file to reply
* notifications
* docker and aws or google app engine
* post-initial-release features
  - voting
  - different croak types (poll, resource bank, plant, tool library, event)
  - going to need to devise a better way of storing and managing croaks to improve performance when there might be thousands of croaks 
  - get by keywords on API
  - possibly take picture from app https://flutter.dev/docs/cookbook/plugins/picture-using-camera
      https://pub.dev/packages/camera
* make a test class with test data structures etc. 

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
  Initial release by August 20th (optimistic), latest 24th
  have docker and server hosting ready by 12th
  release beta test by end of tues:
    general info: what the app is supposed to do, purpose, how to submit bugs and feature suggestions, take screenshots of bugs
    come up with list of specific suggestions i am seeking
      options for long press croak
      voting? or just stick with num of comments?
      should identity association choice eventually be added?
      signify OP in comments
      attach file on replies
  keep tackling as many tasks as possible everyday this week
  write the about page and stuff while at airport
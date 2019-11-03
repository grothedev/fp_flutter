FrogPond mobile application, made with flutter. https://flutter.dev/

TODO:
* save sort preferences
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
* button to show complete list of tags (also get more popular tags)
* hide or encrypt ip addresses on API 
* ability to report posts for illegality or spam
  - increments num reports on croak. on server, if num is high enough, notify admin
* wifi direct
* limit # of tags in request
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
  * has_unread (bool) : are there new comments on any of the croaks to which the user is subscribed?

Data Structure Descriptions: (found in 'models.dart', see file for more detail on variables)
  - AppState: flags and other data that widgets would want to access that can change in real time
  - Query: everything needed for querying the API
  - Croak: provides toMap() to convert a newly made croak (from ComposeCroakScreen) to POST parameters compatible with API.
  - LocalTagsStore: a facade for dealing with tags. stores all tags that are of concern to the user (suggested, custom added by user, etc.) and associates relevant data (used for query, include/exclude mode,), and provides necessary functions.
  - LocalCroaksStore: a facade for dealing with croaks, very similar to LocalTagsStore

State Management:
  - the entire app exists within a StatefulWidget called StateContainer, whose state holds a reference to an instance of the app's AppState state and which itself contains an InheritedWidget called InheritedStateContainer.
  - with this, any widget can access the global app state via StateContainer.of(context).state
  - however, one should not access state directly from a widget, but should use the functions of StateContainerState as middleware, as they handle other relevant tasks related to state modification, such as updated SharedPreferences and updating flags. so StateContainerState can be thought of as a "store"
  - this is why most of my widgets have 'store = StateContainer.of(context)'

Screens:
  - RootView (app.dart): container for the three main screens, has the swipeable bottom tab navbar thing
  - FeedScreen (screens/feed.dart): main croak feed, contains a CroakFeed, has some actions on the action bar specific for the feed
  - SettingsScreen (screens/settings.dart): where the user can adjust query parameters, notification interval, and see the developer's MOTD
  - ComposeCroakScreen (screens/composecroak.dart): where the user can compose a croak with text content, files, and tags
  - CroakDetailScreen (screens/croakdetail.dart): displays details of a single croak (attached file, timestamp, all tags, option to copy url), with comments underneath, and button for user to reply
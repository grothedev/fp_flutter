FrogPond mobile application, made with flutter. https://flutter.dev/

TODO:
* 2021/2/10: provider impl
  * make sure that settings and state restored in RootView
  * move MultiProvider to RootView
* NOTES FROM 2021/1/6 compatibility update:
  * what should remain in util and what to controllers?
  * notifications screen
  * fix duplicate notification code
  * possibly reduce number of requests made
  * remove redundant/unused variables: AppState.loading
* first priority 
  - refactor making replies. fix showing up in root feed. 
  - more options for creating replies
  - loading animation (croaking)
  - refresh suggested tags
* UI notes
  - more spacing between text and underline
  - is border around tag selection necessary?
  - make sure all left hand cases are handled
* FIX bugs discovered 11/11
  - when vote on croak then go back to list, score not updated. (same for voting on replies)
  - comments still in root feed sometimes
  - replies mysteriously got deleted. now they're back
    - currently refactoring the way feed gets croaks a bit. remember to update replies methodology
  - sorting not working and bringing up keyboard
  - go to correct page upon click notification
  - keep an eye on feedOutdated and needsUpdate vars. are they necessary?
    - remove store.needsUpdate() if not needed
* questions
  * should AppState.lastCroaksGet be each croak instead a parent croak of a list of hypothetical replies?
    * this would probably help with score and reply # display in list
  * decouple prefs categories (UI, sort/filter, query)? 
  * when should croaks be deleted from croak-store? to refresh data if any have been deleted
* have croaks get deleted after time of inactivity
* save sort preferences
* implement data analysis (how locations of croaks w/ tags etc. )
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
* wifi direct
* post-initial-release features
  - identify commenters or just OP?
  - different croak types (poll, resource bank, plant, tool library, event)
  - get by keywords on API
  - possibly take picture from app https://flutter.dev/docs/cookbook/plugins/picture-using-camera
      https://pub.dev/packages/camera
* implement usage stats for API

SharedPreferences:
  * last_croaks_get (string) : JSON Map<int, int> ms since croaks were last retreived for each parent id (0=root feed, anything else is replies of some croak)
  * prev_query_hash (int) : hashcode of the query used on the previous remote croak retrieval 
  * lat (double) : latitude of user
  * lon (double) : longitude of user
  * exclusive (bool) : get croaks by contain all(1) or some(0) of given tags
  * radius (int) : geographical radius of query (km)
  * dist_unit (int) : 0 = kilometers ; 1 = miles
  * feed_outdated (bool) : do main feed croaks need to be fetched again?
  * ran_before (bool) : if the app has been run on the device before
  * notify_check_interval (int) : minutes between checking for conditions which send device notification 
  * feed_croaks (string) : a json string representing all of the croaks of the most recent feed the user was presented with
  * local_tags (string) : a json string representing the LocalTagsStore
  * has_unread (bool) : are there new comments on any of the croaks to which the user is subscribed?
  * left_hand (bool) : is the user left handed? 

Data Structure Descriptions: (found in 'models/', see files for more detail on variables)
  - AppState: flags and other data that widgets would want to access that can change in real time
  - Query: everything needed for querying the API
  - Croak: provides toMap() to convert a newly made croak (from ComposeCroakScreen) to POST parameters compatible with API.
  - LocalTagsStore: a facade for dealing with tags. stores all tags that are of concern to the user (suggested, custom added by user, etc.) and associates relevant data (used for query, include/exclude mode,), and provides necessary functions.
  - LocalCroaksStore: a facade for dealing with croaks, very similar to LocalTagsStore
    - croaks : (List<Map>) a copy of the json structure of croaks from the API plus some extra fields
      - listen : (bool) is the user subscribed (listening for new comments)
      - feed : (bool) is the croak on the feed (p_id = 0)
        - unnecessary; just check p_id instead
      - has_unread : (bool) are there comments on this croak that the user has not yet seen?
        - only set to true by bg fetch; set back to false by building of CroakFeed of that croak
      - vis : (bool) is this croak currently visible in any feed?
        - actively changes based on feed filter settings. 
      - replies : (int) number of replies to this croak
      - timestampStr : (String) text to display the datetime of post

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
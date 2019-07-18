FrogPond mobile application, made with flutter. https://flutter.dev/

TODO:
* actually implement sort on croak feed
* display distance on croak list items
* automatically update comments upon submit comment
* intro "tutorial" and better homescreen text
* croak detail screen
	- implement threaded comments (or keep screen stack?)
* research MobX, rxdart, BloC, flux vs redux, get_it, provider, 
* reply form on croak detail screen or dialog from floating action button?
* get by keywords on API
* radius slider with unit select
* notifications
* about page
* put entire roadmap and feature plans and vision here
* URLS to simple display rather than API
* going to need to devise a better way of storing and managing croaks to improve performance when there might be thousands of croaks 
* incorporate way to publish locations of tool libraries, seed banks, general resource stocks

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


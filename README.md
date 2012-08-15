# WishList

Enables users to take a photo of a product, add the product to a wishlist, then share the story with friends.

The product gets stored on the backend server before publishing the story to Facebook.

This sample app demonstrates how to build an Android and iOS app to publish custom Open Graph actions. The sample also includes a server-side component to host the Open Graph objects.

Authors: Christine Abernathy (caabernathy), Vikas Gupta (vksgupta)

<div class="fb-facepile" data-href="" data-action="cookline:cook" data-max-rows="1" data-width="300"></div>
## installing

this section will walk you through the following:

* getting started
* creating your facebook app
* setting up your open graph action types, object types, and timeline units
* setting up the the backend server using heroku cloud services
* installing the android app
* installing the ios app

### getting started

your install package should have the following files:

* backend server (server)
  * photo_upload.php
  * product.php
  * wishlists/birthday.php
  * wishlists/holiday.php
  * wishlists/wedding.php
  * images

* android project (android)
  * android project containing the app

* ios project (ios)
  * xcode project containing the app

to get the sample code do the following:

* install [git](http://git-scm.com/).

* pull the samples package from github:

    git clone git://github.com/fbsamples/wishlist

### creating your facebook app

first set up a facebook app using the developer app:

* create a new [facebook app](https://developers.facebook.com/apps)
* enter the `app namespace` when creating your app. you can choose a simple string to identify your app, such as ''wishlist'', but it must be unique.

### setting up your open graph action types, object types, and timeline units

you can now set up the application's action types, object types, and timeline units:

* go to your app on the facebook [dev app](https://developers.facebook.com/apps)

* go to open graph settings

* in the getting started step, enter "add to" for the action, and "wishlist" for the object.

* edit your action type
  * modify _past tense_ to "added to a"
  * modify _plural past tense_ to "added to their"
  * modify _present tense_ to "is adding to a"
  * modify _plural present tense_ to "are adding to their"
  * save changes and continue

* edit your object type
  * under _object properties_ click on "add another property". enter "wishlist id" in the name field. select "integer" for the type field.
  * save changes and continue

* create an aggregation (we will add this later after defining the product object)
  * save changes and continue

* you should now be in the dashboard (summary) view. click on "create new object type"
  * name the object "product"
  * you should not need to make any changes to the default object settings.
  * save your changes

* edit your "add to" action type once more to add a reference to the "product" object:
  * under _action properties_ click on "add another property". enter "product" in the name field. select "product" for the type field.

* now create the timeline units:
  * click on "create new aggregation"
  * _data to display_ select "product"
  * _sort by_ select "most recent product" (if you cannot select this option, keep the default)
  * _aggregation title_ enter "added on wishlist"
  * _caption lines_ first line, enter "{wishlist.title}"
  * _caption lines_ first line, enter {start_time | date("fb_relative")} at {place}

  * click on "create new aggregation"
  * _data to display_ select "product"
  * _layout style_ select the gallery option
  * _sort by_ select "most recent product" (if you cannot select this option, keep the default)
  * _aggregation title_ enter "birthday wishlist"
  * _caption lines_ first line, enter "{product.title} at {place}"
  * click the advanced link
  * click "add filter"
  * select wishlist.wishlist_id for the filter parameter and 1 as the value to filter on.

  * click on "create new aggregation"
  * _data to display_ select "product"
  * _layout style_ select the gallery option
  * _sort by_ select "most recent product"
  * _aggregation title_ enter "holiday wishlist"
  * _caption lines_ first line, enter "{product.title} at {place}"
  * click the advanced link
  * click "add filter"
  * select wishlist.wishlist_id for the filter parameter and 2 as the value to filter on.

### setting up the the backend server using heroku cloud services

* go to your app on the facebook [dev app](https://developers.facebook.com/apps)

* go to basic settings

* under the cloud services section click on "get started" and follow the instructions for setting up your server-side. note the cloud services hosting url that is generated; you will enter this in a later step.

* edit your [dev app](https://developers.facebook.com/apps) settings to add the heroku information:
  * under basic settings modify _app domain_ to add your heroku host domain

* ensure that you have installed the [heroku toolbelt](http://devcenter.heroku.com/articles/facebook#heroku_account_and_tools_setup) and followed the setup instructions in the email.

* fetch your [server app code](http://devcenter.heroku.com/articles/facebook#editing_your_app)

* add the wishlist server-side php files to your heroku app:
  * copy the server/* files to your heroku local app main directory
  * for the files product.php and wishlists/*.php wherever you find them, replace:
     * `your_app_id` with your app id
     * `your_heroku_server_url` with your heroku host url
     * `your_app_namespace` with the namespace for your facebook app
  * commit and push the local additions up to heroku
    * git add .
    * git commit -am "wishlist"
    * git push heroku master


### installing the android app

for more information on how to set up an android app, see the [android tutorial](https://developers.facebook.com/docs/guides/mobile/android/)

1. launch eclipse

2. ensure you have installed the android plugin.

3. create facebook sdk project - follow the step-2 instructions in the [android tutorial](https://developers.facebook.com/docs/guides/mobile/android/).

4. create the wishlist project :
    4. select __file__ -> __new__ -> __project__, choose __android project__, and then click __next__.
    4. select "create project from existing source".
    4. choose  wishlist folder. you should see the project properties populated.
    4. click finish to continue.

5. add reference to the facebook sdk - follow the step-3 instructions in the [android tutorial](https://developers.facebook.com/docs/guides/mobile/android/).

6. download [apache httpcomponents](http://hc.apache.org/downloads.cgi) and add a reference to the httpmime-4.1.2.jar file:
    6. go to project->properties->java build path->libraries->add external jars->select httpmime-4.1.2.jar->ok

7. follow the //todo in the wishslist.java and add:
    7. add the app id in the wishlist.java->app_id
    7. add the heroku server url to the wishlist.java->host_server_url
    7. add wishlist object urls to the wishlist.java->wishlist_objects_url
    7 in the addtotimeline() function, add your namespace:{action} in the utility.masyncrunner.request("me/{namespace}:{add_to_action}", wishlistparams, "post", new addtotimelinelistener(), null);

8. add app keyhash to the app setting, follow the step-4 in the [android tutorial](https://developers.facebook.com/docs/guides/mobile/android/).

9. and you are done and ready to compile the project:
    9. from the project menu, select "build project".

10. hopefully the project will compile fine. next run the app on the emulator or on the phone (see http://developer.android.com/guide/developing/eclipse-adt.html#runconfig for more details.)
    10. if you plan to run on the emulator, ensure you have created an android virtual device (avd):
        10. go to window -> android sdk and avd manager -> click new
        10. provide a name (avd 2.3 e.g.) and choose the target (android 2.3 if available).
        10. click 'create avd' at the bottom and that should create an avd which you can run the app on described  next.
    10. go to run->run configurations->android application->create a new run configuration by clicking the icon with '+' button on it.
    10. name it 'wishlist'
    10. under the project, browse and choose wishlist
    10. go to target tab -> choose manual if you wish to run on the phone, else choose automatic and select an avd created in step 10.1
    10. click run and your 'hackbook for android' app should be up and running.

### installing the facebook android app

you will need to have the facebook android application on the handset or the emulator to test single sign on. the sdk includes a developer release of the facebook application that can be side-loaded for testing purposes. on an actual device, you can just download the latest version of the app from the android market, but on the emulator you will have to install it yourself:

      adb install fbandroid.apk

**simulating location on emulator.**

* you can simulate the location on simulator by
  * launch the simulator
  * login the user
  * open command prompt and type 'telnet localhost 5554'
  * type geo fix -122.152004 37.416033 which is facebook hq lat lon
  * this sets the emulator location and will then fetch nearby places.

**quick code overview**

* the main class which does the layout, login, and posting the cog story.
  * initfacebook() - initialize the facebook object, restore session if available and display the login button.
  * maddtotimeline.setonclicklistener(new onclicklistener() - this activates the photo upload and publishing the cog story
  * uploadphoto() - upload the product image in a new thread at host_server_url + host_photo_upload_uri and on successful upload, triggers the addtotimeline()
  * addtotimeline() - publish a cog story using the graph api
  * onactivityresult()  - called on successful authentication and after user pick a photo from the media gallery.
  * fbapisauthlistener and fbapislogoutlistener() - authentication listeners.
  * requestuserdata() - get user's name, profile pic and fetch his current location via fetchcurrentlocation()
  * fetchplaces() - fetch nearby places


### installing the ios app

**configuring the app**

1. using xcode open up wishlist/wishlist.xcodeproj

1. set up the facebook ios sdk:
   1. get the latest facebook ios sdk from github: git clone git://github.com/facebook/facebook-ios-sdk.git
   2. you should see a folder called facebook-ios-sdk/src that contains the sdk
   3. drag the src folder to the wishlist project. you may choose to copy the items over into your project.

2. set up your app id:
    1. open up appdelegate.m, add your app id by changing:

             nsstring * const kappid = nil;

     to:

             nsstring * const kappid = @"your_app_id";

   1. open up wishlist/supporting files/wishlist-info.plist
   1. navigate to url types > item 0 > url schemes > item 0
   1. replace fbyour_app_id with "fb" followed by your app id, e.g. fb123456 if your app id is 123456

3. set up your bundle identifier
   1. open up wishlist/supporting files/wishlist-info.plist
   1. edit the bundle identifier information and make sure it matches the settings in the facebook dev app

4. set up to publish to your own backend server (assumption here is you set up a heroku server and copied over the sample files)
   1. open up homeviewcontroller.m
   1. replace the kbackendserver string with your back-end server url
   1. in the apigraphaddtowishlist method, replace: `samplewishlist:add_to` with: `your_app_namespace:add_to` where your_app_namespace corresponds to the value defined earlier in the facebook dev app.

**configuring facebook distribution**

* edit your [dev app](https://developers.facebook.com/apps) basic settings to add the [native ios app settings](https://developers.facebook.com/docs/mobile/ios/build/#linktoapp):
  * modify _iphone app store id_ to add any valid itunes app id
  * enable the _configured for ios sso_ setting

## contributing

all contributors must agree to and sign the [facebook cla](https://developers.facebook.com/opensource/cla) prior to submitting pull requests. we cannot accept pull requests until this document is signed and submitted.

## license

copyright 2012-present facebook, inc.

you are hereby granted a non-exclusive, worldwide, royalty-free license to use, copy, modify, and distribute this software in source code or binary form for use in connection with the web services and apis provided by facebook.

as with any software that integrates with the facebook platform, your use of this software is subject to the facebook developer principles and policies [http://developers.facebook.com/policy/]. this copyright notice shall be included in all copies or substantial portions of the software.

the software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. in no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

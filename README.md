# WishList Sample App

Enables users to take a photo of a product, add the product to a wishlist, then share the story with friends.

The product gets stored on the backend server before publishing the story to Facebook.

This sample app demonstrates how to build an Android and iOS app to publish custom Open Graph actions. The sample also includes a server-side component to host the Open Graph objects.

Note: To access the sample that works with Facebook SDK 2.x for iOS see the v1.0 tagged version.

Authors: Christine Abernathy (caabernathy), Vikas Gupta (vksgupta)

<div class="fb-facepile" data-href="" data-action="cookline:cook" data-max-rows="1" data-width="300"></div>
## installing

This section will walk you through the following:

* Getting started
* Creating your Facebook app
* Setting up your open graph action types, object types, and timeline units
* Setting up the the backend server using heroku cloud services
* Installing the android app
* Installing the ios app

### Getting started

Your install package should have the following files:

* backend server (server)
  * photo_upload.php
  * product.php
  * wishlists/birthday.php
  * wishlists/holiday.php
  * wishlists/wedding.php
  * images

* Android project (android)
  * android project containing the app

* iOS project (iOS)
  * xcode project containing the app

To get the sample code do the following:

* Install [git](http://git-scm.com/).

* Pull the samples package from github:

    git clone git://github.com/fbsamples/ios-android-wishlist

### Creating your Facebook app

First set up a Facebook app using the developer app:

* Create a new [Facebook app](https://developers.facebook.com/apps)
* Enter the `app namespace` when creating your app. you can choose a simple string to identify your app, such as ''wishlist'', but it must be unique.

### Setting up your open graph action types, object types, and timeline units

You can now set up the application's action types, object types, and timeline units:

* Go to your app on the Facebook [App Dashboard](https://developers.facebook.com/apps)

* Go to open graph settings

* In the getting started step, enter "add to" for the action, and "wishlist" for the object.

* Edit your action type
  * Modify _past tense_ to "added to a"
  * Modify _plural past tense_ to "added to their"
  * Modify _present tense_ to "is adding to a"
  * Modify _plural present tense_ to "are adding to their"
  * Save changes and continue

* Edit your object type
  * Under _object properties_ click on "add another property". enter "wishlist id" in the name field. select "integer" for the type field.
  * Save changes and continue

* Create an aggregation (we will add this later after defining the product object)
  * Save changes and continue

* You should now be in the dashboard (summary) view. click on "create new object type"
  * Name the object "product"
  * You should not need to make any changes to the default object settings.
  * Save your changes

* Edit your "add to" action type once more to add a reference to the "product" object:
  * Under _action properties_ click on "add another property". enter "product" in the name field. select "product" for the type field.

* Now create the timeline units:
  * Click on "create new aggregation"
  * _data to display_ select "product"
  * _sort by_ select "most recent product" (if you cannot select this option, keep the default)
  * _aggregation title_ enter "added on wishlist"
  * _caption lines_ first line, enter "{wishlist.title}"
  * _caption lines_ first line, enter {start_time | date("fb_relative")} at {place}

  * Click on "create new aggregation"
  * _data to display_ select "product"
  * _layout style_ select the gallery option
  * _sort by_ select "most recent product" (if you cannot select this option, keep the default)
  * _aggregation title_ enter "birthday wishlist"
  * _caption lines_ first line, enter "{product.title} at {place}"
  * Click the advanced link
  * Click "add filter"
  * Select wishlist.wishlist_id for the filter parameter and 1 as the value to filter on.

  * Click on "create new aggregation"
  * _data to display_ select "product"
  * _layout style_ select the gallery option
  * _sort by_ select "most recent product"
  * _aggregation title_ enter "holiday wishlist"
  * _caption lines_ first line, enter "{product.title} at {place}"
  * Click the advanced link
  * Click "add filter"
  * Select wishlist.wishlist_id for the filter parameter and 2 as the value to filter on.

### Setting up the the backend server using heroku cloud services

* Go to your app on the Facebook [App Dashboard](https://developers.facebook.com/apps)

* Go to basic settings

* Under the cloud services section click on "get started" and follow the instructions for setting up your server-side. note the cloud services hosting url that is generated; you will enter this in a later step.

* Edit your [App Dashboard](https://developers.facebook.com/apps) settings to add the heroku information:
  * Under basic settings modify _app domain_ to add your heroku host domain

* Ensure that you have installed the [heroku toolbelt](http://devcenter.heroku.com/articles/facebook#heroku_account_and_tools_setup) and followed the setup instructions in the email.

* Fetch your [server app code](http://devcenter.heroku.com/articles/facebook#editing_your_app)

* Add the wishlist server-side php files to your heroku app:
  * Copy the server/* files to your heroku local app main directory
  * For the files product.php and wishlists/*.php wherever you find them, replace:
     * `your_app_id` with your app id
     * `your_heroku_server_url` with your heroku host url
     * `your_app_namespace` with the namespace for your Facebook app
  * Commit and push the local additions up to heroku
    * git add .
    * git commit -am "wishlist"
    * git push heroku master


### Installing the android app

For more information on how to set up an android app, see the [android tutorial](https://developers.facebook.com/docs/guides/mobile/android/)

1. Launch eclipse

2. Ensure you have installed the android plugin.

3. Create Facebook SDK project - follow the step-2 instructions in the [android tutorial](https://developers.facebook.com/docs/guides/mobile/android/).

4. Create the wishlist project :
    4. Select __file__ -> __new__ -> __project__, choose __android project__, and then click __next__.
    4. Select "create project from existing source".
    4. Choose  wishlist folder. you should see the project properties populated.
    4. Click finish to continue.

5. Add reference to the Facebook SDK - follow the step-3 instructions in the [android tutorial](https://developers.facebook.com/docs/guides/mobile/android/).

6. Download [apache httpcomponents](http://hc.apache.org/downloads.cgi) and add a reference to the httpmime-4.1.2.jar file:
    6. Go to project->properties->java build path->libraries->add external jars->select httpmime-4.1.2.jar->ok

7. Follow the //todo in the wishslist.java and add:
    7. Add the app id in the wishlist.java->app_id
    7. Add the heroku server url to the wishlist.java->host_server_url
    7. Add wishlist object urls to the wishlist.java->wishlist_objects_url
    7. In the addtotimeline() function, add your namespace:{action} in the utility.masyncrunner.request("me/{namespace}:{add_to_action}", wishlistparams, "post", new addtotimelinelistener(), null);

8. Add app keyhash to the app setting, follow the step-4 in the [android tutorial](https://developers.facebook.com/docs/guides/mobile/android/).

9. And you are done and ready to compile the project:
    9. From the project menu, select "build project".

10. Hopefully the project will compile fine. next run the app on the emulator or on the phone (see http://developer.android.com/guide/developing/eclipse-adt.html#runconfig for more details.)
    10. If you plan to run on the emulator, ensure you have created an android virtual device (avd):
        10. Go to window -> android sdk and avd manager -> click new
        10. Provide a name (avd 2.3 e.g.) and choose the target (android 2.3 if available).
        10. Click 'create avd' at the bottom and that should create an avd which you can run the app on described  next.
    10. Go to run->run configurations->android application->create a new run configuration by clicking the icon with '+' button on it.
    10. Name it 'wishlist'
    10. Under the project, browse and choose wishlist
    10. Go to target tab -> choose manual if you wish to run on the phone, else choose automatic and select an avd created in step 10.1
    10. Click run and your 'hackbook for android' app should be up and running.

### Installing the Facebook Android app

You will need to have the Facebook Android application on the handset or the emulator to test single sign on. the sdk includes a developer release of the Facebook application that can be side-loaded for testing purposes. on an actual device, you can just download the latest version of the app from the android market, but on the emulator you will have to install it yourself:

      adb install fbandroid.apk

**Simulating location on emulator.**

* You can simulate the location on simulator by
  * Launch the simulator
  * Login the user
  * Open command prompt and type 'telnet localhost 5554'
  * Type geo fix -122.152004 37.416033 which is Facebook HQ lat lon
  * This sets the emulator location and will then fetch nearby places.

**Quick code overview**

* The main class which does the layout, login, and posting the cog story.
  * initfacebook() - initialize the Facebook object, restore session if available and display the login button.
  * maddtotimeline.setonclicklistener(new onclicklistener() - this activates the photo upload and publishing the cog story
  * uploadphoto() - upload the product image in a new thread at host_server_url + host_photo_upload_uri and on successful upload, triggers the addtotimeline()
  * addtotimeline() - publish a cog story using the graph api
  * onactivityresult()  - called on successful authentication and after user pick a photo from the media gallery.
  * fbapisauthlistener and fbapislogoutlistener() - authentication listeners.
  * requestuserdata() - get user's name, profile pic and fetch his current location via fetchcurrentlocation()
  * fetchplaces() - fetch nearby places


### Installing the iOS app

**Configuring the App**

Using Xcode open up Wishlist/Wishlist.xcodeproj

1. Install the Facebook SDK for iOS - Installing the samples requires you to add the Facebook SDK, the Facebook SDK resource bundle, and the Facebook SDK deprecated headers for some samples. The missing required libraries and files will show up in red under the `Frameworks` folder when you open up the project. Simply delete those references then do the following:
   1. Add the Facebook SDK for iOS Framework by dragging the `FacebookSDK.framework` folder from the SDK installation folder into the Frameworks section of your Project Navigator.
   1. Choose 'Create groups for any added folders' and deselect 'Copy items into destination group's folder (if needed)' to keep the reference to the SDK installation folder, rather than creating a copy.
   1. Add the Facebook SDK for iOS resource bundle by dragging the `FacebookSDKResources.bundle` file from the `FacebookSDK.framework/Resources` folder into the Frameworks section of your Project Navigator.
   1. As you did when copying the Framework, choose 'Create groups for any added folders' and deselect 'Copy items into destination group's folder (if needed)'
   1. Add the Deprecated Headers. The headers can be found here `~Documents/FacebookSDK/FacebookSDK.framework/Versions/A/DeprecatedHeaders`. Drag the whole DeprecatedHeaders folder and deselect the ''Copy items into destibation group's folder (if needed)'' option to add the headers as a reference.

2. Configure your app Id.
   1. Open up Wishlist/Supporting Files/Wishlist-Info.plist
   1. Navigate to Url types > Item 0 > URL Schemes > Item 0
   1. Replace fbYOUR_APP_ID with "fb" followed by your app id, e.g. fb123456 if your app id is 123456
   1. Change the FacebookAppID key value from YOUR_APP_IF to your app Id, e.g. 123456

3. Set up your bundle identifier
   1. Open up Wishlist/Supporting Files/Wishlist-Info.plist
   1. Edit the bundle identifier information and make sure it matches the settings in the Facebook App Dashboard

4. Set up to publish to your own backend server (assumption here is you set up a heroku server and copied over the sample files)
   1. Open up Viewcontroller.m
   1. Replace the kBackEndServer string with your back-end server url
   1. In the `publishAddToWishlist` method, replace: `samplewishlist:add_to` with: `your_app_namespace:add_to` where `your_app_namespace` corresponds to the value defined earlier in the Facebook App Dashboard.

**Configuring Facebook Distribution**

* Edit your [App Dashboard](https://developers.facebook.com/apps) basic settings to add the Native iOS App Settings:
  * Enable the _configured for ios sso_ setting

## Contributing

All contributors must agree to and sign the [Facebook cla](https://developers.facebook.com/opensource/cla) prior to submitting pull requests. we cannot accept pull requests until this document is signed and submitted.

## License

Copyright 2012-present Facebook, Inc.

You are hereby granted a non-exclusive, worldwide, royalty-free license to use, copy, modify, and distribute this software in source code or binary form for use in connection with the web services and apis provided by Facebook.

As with any software that integrates with the Facebook platform, your use of this software is subject to the Facebook developer principles and policies [http://developers.facebook.com/policy/]. this copyright notice shall be included in all copies or substantial portions of the software.

The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. in no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

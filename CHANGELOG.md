7.63
-----
- Show the Up Next bar on the tab bar. [#1613]
- New design for the Podcasts grid layouts. [#1628]
- Shake the device to restart Sleep Timer [#1627]
- Playback fades out when finishing a sleep timer [#1629]

7.62
-----
- Sleep Timer restarts automatically if you play again within 5 minutes [#1612]

7.61
-----
- Opening a shared podcast episode link with the current position, now opens on the right position. [#5]
- Allow sharing of bookmarks directly on the bookmarks list. [#1558]
- Adds support to displaying chapters from RSS [#1574]
- Adds support to displaying episode artwork [#1574]

7.60
-----
- Profile bookmark screen where all user bookmarks can be managed. [#1500]
- Fix the player getting stuck and not reopening [#1529]
- Visually mark played episodes in search results [#928]

7.59
-----
- Fixes Push Notification registration after restoring the app from a backup. [#1198]

7.58
-----
- Fixes an issue where adding a new podcast could fail at the first try. [#1457]

7.57
-----
- Implement new introductory offer for Plus: 50% off on the first year. [#1362] [internal]
- Fixes an issue where the auto add to top/bottom would be reset. [#788]

7.56
-----
- Allows navigation from the Player to the Podcast screen by tapping on Podcast name [#1322]

7.55
-----
- Only show 'Cancel Subscription' button on Account Profile if the user has an active, renewing subscription [#1032]
- Fix rows layouts on WatchOS 10 for podcast episode list, file list, filters and downloads [#1183]
- Adds Star button to CarPlay Now Playing screen [#1332]

7.54
-----
- Adds a button to export the database and preferences from the Help & Feedback view [#1257]
- Fixes star functionality on native Now Playing widgets (lock screen and control centre) for iOS 17.1 and later [#1195]
- Adds theme support to the Up Next [#1265]
- Now Playing scrubber is now interactive with Accessibility VoiceOver enabled [#1318]

7.53
-----
- Moves Bookmarks out of Early Access: [#1224]
- Shows the Bookmarks tab after Chapters [#1240]
- Makes the player transition faster, smoother and with a new effect [#1090]
- Attempts to fix podcast being removed from their folders [#1239]

7.52
-----
- Enables Bookmarks for Early Access: [#1202]
- Enables Playback 2023 [#1206]

7.51
-----
- Improvements on battery consumption when trim silence is not enabled [#1186]
- TestFlight: Disable new show notes endpoint and custom RSS artwork due to memory issues

7.50
-----
- Further improves performance when opening a large Up Next queue in the Apple Watch [#1139]

7.49
-----
- Improves performance when opening a large Up Next queue in the Apple Watch [#950]
- Fixes the app playing automatically after putting AirPods on the case [#1132]
- Enables Patron [#1146] [Internal]

7.48
-----
- Fix importing podcasts route [#1091]
- Fixes the player tab scroll indicator colors [#1120]
- Fixes an issue where the player tabs may not render correctly [#1119]
- Fixes the play/pause on interactive widgets not working for user files [#1123]

7.47
-----


7.46
-----
- Added import support for audio and movie files [#1039]
- Adds a new show notes endpoint [#1033]
- Show episode artwork from the feed if "Use Embedded Artwork" is enabled [#1033]
- Adds a new Headphone Controls section in the settings [#1027]
- Moves the Remote Skips Chapters setting in the General section to Headphone Controls [#1027]

7.45
-----
- Attempt to fix a crash when switching episodes [1019]

7.44
-----
- Add a share action from the episode row [#966]
- Speed up checking if a podcast is in UpNext, slightly improving app responsiveness [#951]

7.43
-----
- The search bar on the podcasts tab is now visible by default [#929]
- Fix spacing for the search bar when creating/editing a folder [#912]
- Adds Autoplay, if user's Up Next is empty the app will keep playing episodes from the same list [#957]


7.42
-----


7.41
-----
- Improve support section to help the user to send Apple Watch logs

7.40
-----
- Add a Status Page so the user can check their connection to our services
- When all chapters in a file are hidden, make them visible in the Chapters UI

7.39
-----
- Removed the starred filter from the list of default filters

7.38
-----
- Chapters that are hidden will no longer appear
- Chapter titles/images now display while scrubbing in the player
- Embedded artwork: extract embedded artwork from episodes that are being streamed (#829)

7.37
-----
- Login: added capability to sign into Pocket Casts using Google and Apple accounts

7.36
-----
- Updated sort order for Chinese podcast titles from Unicode-based to pinyin (#775)
- Fixed and issue where the multi-selection header would overlap the search bar on certain devices depending on their screen size (#785)
- Search: improved the search with a new design and added the ability to search for episodes (#796)

7.35
-----
- Discover: Top carousel now scrolls automatically (#790)

7.34
-----
- Added import OPML from url option (#737)


7.33
-----
- CarPlay: Improved speed and reduced crashing (#705)
- CarPlay: Tapping an episode now goes to the now playing screen (#702)
- CarPlay: The mark as played and chapter icons now update with the dark/light mode (#700)
- CarPlay: Fixed many issues where the UI would not refresh correctly (#699)
- Auto Add Up Next: Fixed an issue that could cause items in Auto Add Up Next to not be added (#711)


7.32
-----
- When connected to CarPlay the Up Next Queue will more consistently display at the top of the podcasts list (#680)
- Fixed an issue where the Up Next queue doesn't continue playing the next episode when connected to AirPlay (#676)
- Show Starred for logged out users (#685)
- Fixed an issue where the swipe actions in Up Next could be triggered when trying to reorder a row (#684)

7.31
-----
- Fixed an issue where the close button was rendered as a solid white circle when the Dark Contrast theme was active (#552)
- Updated the import process in Settings (#641)
- Fixed an issue where the up next queue could be cleared or replaced (#661)
- Updated the Now Playing metadata to put podcast author in the Artist fields to fix Siri responses and Siri Suggestions (#48)
- Fixed shownotes not always scrolling back to the beginning when new episode is loaded (#651)
- Fixed an issue where logged out users were incorrectly prompted to sign in when starring episodes on the Now Playing screen (#653)
- Fixed an issue where playback speed was incorrectly set to 1x when using the "Play my podcasts" Siri intent (#41)

7.30
-----
- Display gravatar under Profile (#584)
- Fixed some podcasts being excluded from the Apple Podcasts import (#640)

7.29
-----
- Fixed Edit Folder screen layout (#53)
- Fixed an issue where episodes wouldn't resume downloading on next launch if the app was force quit (#472)
- Fixed an issue where the podcast artwork wasn't appearin in the Now Playing Siri suggestions (#579)
- Fixed a crash that could happen when scrubbing the player (#605)

7.28
-----
- Updates the onboarding and login process: (#548)
- Updates the end of year calculation to include the month of December (#554)
- Updates the End of Year stats designs
- Fixes an issue where the login button is not accesible on very small devices (#597)

7.27
-----
- Add End of Year stats
- Fixed the download indicator width in iOS 14 in Episode list cells.

7.26
-----
- Fixed a search bar layout issue when adding/removing podcasts to folder (#378)
- Fixed About screen dark theme background in light mode (#339)
- Adding select/deselect all podcasts button to folder creation (#143)
- Fixed an issue where opening a Featured Episode on the Discover view would crash the app if the podcast episode could not be found (#58)

7.25
-----
- Fixed a crash that could happen when playing an episode while the app is in the background (#345)
- Fixed a crash where a sync account has started listening to a local file on one device and visits the up next queue on a different device. (#371)
- Fixed an issue where the episode totals would not display above the podcast episode list in iOS 14 (#287)
- Fixed an issue where the Up Next queue wouldn't reset when playing all items from a filter. (#375)
- Improved OPML import to support poll uuids (#367)

7.24
-----
- Fixed an iOS 16 issue where a feedback text field had a light background for a dark theme or vice versa. (#301)
- Fixed an issue where the keyboard would dismiss when resetting search text on discover. (#321)
- Fixed an issue where the support feedback box would be unusable on smaller devices (#330)
- Add haptic feedback when the user pulls to refresh (#351)

7.23
-----

- Add a pull to refresh to the podcast list and profile view (#239)
- Add a helpful alert if the user is signed out in the background (#251)

7.22
-----

- Add "Launch App" lock screen widget for iOS 16 (#300)
- Add "Now Playing" lock screen widget for iOS 16 (#229)
- Add "Up Next" count lock screen widget for iOS 16 (#231)
- Add "Up Next" episode details lock screen widget for iOS 16 (#235)
- Fixed an issue where the timer screen would show wrong time when unlocking the phone (#211)
- Fixed an issue where some podcasts won't play on iOS 16 (#213)
- Fixed an issue where the plus pricing info wouldn't be updated on the account details view (#225)

7.21
----

- Fixed an issue where the user would be kicked out of the upgrade flow if they tried to sign in (#142)
- Make the button that clears the Up Next queue to have red colors indicating destructive actions (#152)
- Make use of the whole available space on Apple Watch when showing playback controls (#179)

7.20.2
----

- Fixed the initial sync after migrating to 7.20 (#134)
- Fix an issue where ghost episodes could appear in the filters even if you didn't subscribe to the podcast (#137)

7.20.1
----

- Fix an issue where the podcasts order was being changed after migrating to the latest version (#131)

7.20
----

- Make the delete folder button to fill the whole row (#79)
- Limit folders to 100 chars (#80)
- Fix an issue where the sort order was ignoring the search text when creating a folder (#81)
- Fix an issue with Folders appearing as black square in CarPlay (#88)
- Fix an issue where the podcast name was being truncated on the podcast details screen [#96]
- Fix an issue where changing the folder on the podcast details view would not be sync'd with the server [#103]

### 7.20

#### 883

#### 882
- Match the Android / Web client sort order for folders that start with emoji (#63)
- Sort empty folders to the end of the list when sorting by Episode Release Date (#70)

#### 881
- Make the delete folder button to fill the whole row (#79)
- Limit folders to 100 chars (#80)
- Fix an issue where the sort order was ignoring the search text when creating a folder (#81)
- Fix an issue with Folders appearing as black square in CarPlay (#88)
- Fix an issue where the podcast name was being truncated on the podcast details screen [#96]
- Fix an issue where changing the folder on the podcast details view would not be sync'd with the server [#103]

#### 880
- Fixed a crash when creating a folder on iOS 14
- Fixed truncated text on the Plus feature descriptions on iOS 14
- Fixed a Dark Mode issue on the About screen for iOS 14
- Updated the Google Cast library to use a dynamic framework

#### 879
- Fixed an issue where on upgrading from 7.19 -> 7.20 folders you created previously might be missing or podcasts might not be in the right folders
- Fixed an issue where some text on the Pocket Casts widget would be overlapping when you choose a very large text size
- Fixed an issue where when you change themes you might have the wrong folder colour
- Imported the latest translations
- Adding support for episode list website link
- Peace out my dude(tte)s, this was my last ever iOS build. Be excellent to each other. - Russell

#### 878
- Fixed issues with the tinting of the Up Next button in the player and the play button on single episode lists
- Added an option to not send chapter titles over to Bluetooth and other devices (on by default to match how it currently works)

#### 877
- Fixed theming issues with some folders views when the app was backgrounded and then brought back to foreground

#### 876
- Fixed issues on iPad with support and folders pages
- ALL THE CRASH FIXES
  - Fixed our number one reported crash (hopefully!)
  - Fixed a crash in the discover area that could happen if you tap podcasts that hadn't loaded yet
  - Fixed some more CarPlay related issues, including an out of memory crash
  - Fixed 2 other crashes that were less common but still important

#### 875
- Fixed an issue with the remaining time in a chapter could be cut off
- Updated what happens when you tap on the folder icon for a podcast that's already in a folder. Now you can remove it, change it to another folder or go to the folder
- Added a What's New Page for ### 7.20
- Fixed an issue where the play button and the up next button in the mini player could be the wrong colours
- Fixed the colour of the placeholder text in search boxes

#### 874
- Added folder information to Pocket Casts Plus upgrade views
- Added empty folder design
- Fixed some performance/layout issues on the support contact us page
- Folder button on the podcast page is now hidden if you don't have Plus
- Folder button on the podcast list page now updates correctly based on your Plus status

#### 871, 872, 873
- Fixed a memory leak issue
- Watch app re-written in SwiftUI 😱
- Fixed an issue where your car could become posessed by Wednesday 13
- Updated translations and fixed various translation issues
- Fixed an issue where timestamps in links would be incorrectly detected in show notes
- Adding folder sync code, so that folders you create, edit and delete now sync to the server
- Added home grid sync code. The order of your home grid (including how you have it sorted) is now synced to your account
- Added folders to CarPlay
- Added folders to Apple Watch
- Tweaked the layout of episode lists in the discover section
- Added download indicator to the now playing item in Up Next
- Fixed a CarPlay crash
- Fixed an issue where some download requests could be sent without the Pocket Casts user agent
- Fixed an issue where the app wouldn't refresh if only used from CarPlay
- 871 got stuck in processing, 872 crashed on launch, hence 873 :)

#### 867
- Fixed an issue where the mini player would cover podcasts in a folder
- Folder names are no longer optional, now if you don't choose one we'll choose one for you ;)
- Minor fixes and update for Xcode 13.3

#### 866
- Fixed a display issue with the limit/archive/episode count labels on the podcast page
- Fixed an issue where your Up Next list could be replaced by an old server one on sign-in
- Added France (Canada) and Spanish (Mexico) translations
- Updated various translations with betterer words
- Added some logs to diagnose issues where a podcast might not be auto added to up next
- Fixed the theming of the progress dialog in the support section
- Fixed the theming of the close and search boxes on the new folder create page

#### 864
- Fixed an issue where user uploaded episodes could start from the wrong spot if they were played on another device
- Fixed a translation issue where in some places in the app "1 podcast" would show instead of 0
- Another attempt at fixing the same crash as in the last build (2nd times a charm?)
- Folders in the choose folder dialog are now sorted
- Fixed an issue where editing a folder might not apply those edits to the main grid
- The search on the Podcasts page now also searches folders and the podcast author

#### 864
- Testing a fix for a new crash introduced in earlier builds of ### 7.20

#### 863
- Fixed a regression where sorting by episode release date on the main podcasts page was very slow
- Added a few more performance related traces to the app

#### 862
- Updated various dependencies
- Imported latest translations, including translation improvements/updates for various languages
- Refactored the code that renders badge on the podcast list page

#### 861

- Folders!
  - You can now create folders on the podcast list page
  - Note there's no syncing code yet, so these won't sync across devices
  - Still a bit of polish and UI missing
  - This will be a Pocket Casts Plus only feature
- Added some temporary performance monitoring code to take make our CPU/battery even smaller than it currently is.

### 7.19.2 Build 860
- Fixed an issue with the discover and podcast search boxes when you entered lots of text into them
- Fixed an issue with skip first and last times where holding down on the control would change both numbers
- Improved some bits of the Russian translation
- Fixed some truncation issues on the Appearance page
- Placeholder text on the change email and change password page added to strings to be translated

### 7.19.2 Build 859
- Fixed some typo's in the app, including one on the about page
- Fixed an issue where the mini player could dissapear even if you were playing something
- Updated various libraries the app depends on

### 7.19.1 Build 858
- Imported even more translations

### 7.19.1 Build 857
- Imported some more translations
- Made the second half of the add to up next animation user interactable
- Fixed a display issue where the app would say you had 1 podcast in auto add to Up Next when you had 0
- Fixed an issue where podcast grouping was being applied alphabetically, so it didn't work properly in other languages

### 7.19.1 Build 856
- Import latest translations

### 7.19.1 Build 855
- Fixed an issue with the navigation bar colour and the Google Cast dialog
- Fixed some memory leaks
- Made the Appearance themes more straightforward. Now if you choose to match iOS light/dark mode you can explicitly pick the light and dark themes you want to use. If you don't, well you can still pick one theme like always.
- Added some extra logging to help find an episode syncing issue
- Fixed "Podcasts" on the profile page not being translated

### 7.19.1 Build 854
- Fixed an issue where the cancel button could overlap the search box on some pages
- Fixed an issue with the About page and themes
- Fixed an issue where after performing a multi-select in Up Next, some of the table cells could be in the wrong state

### 7.19.1 Build 853
- Fixed a crash on Apple Watch when the locale was set to Spanish, Portuguese or Chinese.
- Added a slightly more friendly about page
- Updated Google Cast library for hopefully smoother and betterer casting

### 7.19 Build 852
- Removed some very ancient code that used to try and clean up episode titles by removing the podcast name from them. Most podcasts don't do this anymore and it was just causing weird issues
- Fixed an issue where if you browsed discover in some regions it would reload whenever you came back to it
- Imported latest available translations for app

### 7.19 Build 851
- Added some more places we missed in terms of translations
- Fixed some padding/wrapping/display issues with some translations
- Fixed video player being able to rotate to upside down on phones with home buttons
- Changed feedback form to go to our new Zendesk instance

### 7.19 Build 850
- Fixes an issue where the active Google Cast dialog was cut off under the navigation bar
- Fixed issues with the sizing of the refresh button on the profile tab
- Fixed an issue where upload/download progress was being reported incorrectly
- Fixed a colour issue with table footers
- Fixed issues with headings on some translations not fitting properly
- Added initial support for parts of the new translation flow that didn't have translations (they still won't in this build, but they are now localised)
- Improved padding of the add filter button

### 7.19 Build 849
- Fixed the password reset page having "Email Address" as the actual text in the field instead of as a placeholder
- Updated some translations

### 7.19 Build 848
- Added Japanese translation
- Improved security of debug log upload

### 7.19 Build 847
- Fixed an issue that could cause the play/pause buttons to be tinted grey instead of the colour they should be
- Added final translations for all the other languages (except Japanese, one more to go!)

### 7.19 Build 846
- Added final translations for German, Russian, Spanish and Portuguese (the other languages are still missing some translations)
- Fixed some issues with lists getting cut off when they shouldn't
- Fixed the selection states on the Appearance page not working correctly
- Fixed issues with Siri actions not refreshing properly
- Improved the debug log submission page, including adding an opt-out option
- Fixed an issue where auto downloads that started over WiFi could continue over cellular even your settings were configured for WiFi only
- Fixed a colour issue on the filter create page
- Fixed an issue with the download stop button not being aligned properly

### 7.19 Build 845
- Fixed more translation length issues with truncation and things not fitting properly
- Fixed an issue where show note formatting might be wrong
- Fixed scroll to top behaviour on Podcast, Discover and Filter pages
- Translated more parts of the app
- Missing translations will now be shown in English, rather than being completely blank (we're still waiting on about 30 translations, so you will see a little bit of English here and there)

### 7.19 Build 844
- Added German, Spanish, Brazilian Portuguese, Dutch, Swedish, Chinese (China, Taiwan), Russian, Italian and Japanese translations
- Fixed the non-working submission form
- Fixed some more translation issues with text being truncated, etc

### 7.19 Build 843
- Added French translation
- Updated various components that where expecting fixed size English strings
- Replaced Email form that didn't work without Apple Mail configured with custom feedback form. (Known issue: this doesn't currently submit)

### 7.19 Build 842
- Fixed some issues with iOS Widget layout, including placeholder artwork and text alignment
- Temporary fix for long press options being missing on Now Playing, Podcast List, Podcast Page, Up Next and Files page
- Fixed an issue with the play/pause button state
- Fixed the "Files" label incorrectly saying "Files Settings" on Apple Watch

### 7.19 Build 841
- Fixed some issues with the spacing for multi-select and the mini player on the Files and Filters pages
- Removed a re-occurring log message that wasn't very useful from the debug log

### 7.19 Build 840
- Fixed an issue with the navigation bar on the profile page
- Fixed the flashing white bar when the podcast page updates (and a related weird grey bar issue)

### 7.19 Build 839
- Added missing sort icon on podcast grid
- Fixed an issue where the episode count and archive count were displayed wrong on the podcast page
- Fixed an issue where the multi-select action bar wouldn't appear on some pages
- Fixed the profile page having the numbers listed twice for stats
- Fixed the last episode on the Files page being cut off by the mini player

### 7.19 Build 836, 837, 838
- Fix some iOS 15 issues with the navigation and tab bar styling

### 7.19 Build 835
- Fixed artwork loading issues on the widget
- Fixed an issue that caused some share links to open in Safari instead of the app
- Fixed Up Next drag handles being missing on iOS 15
- Removed DeckTransition library, all cards are native now
- All app strings extracted into strings file, ready for localisation into 12 new languages, how exciting!

### 7.18.1 Build 834
- Added release notes

### 7.18.1 Build 833
- Background refresh improvements

### 7.18.1 Build 832
- Fixed iOS 15 related crash on the podcast settings page
- Fixed an accessibility issue where you couldn't close the Sleep Timer and Effects dialogs properly
- Fixed an issue with watch complications
- Increased minimum iOS version to 14, since 98% of our users are now on 14 or higher. This also meant removing a lot of old iOS 12 handling related code, including the old today widget. If you notice anything weird in this build let us know!
- Updated to new iOS 13+ background refresh API

### 7.18.1 Builds 825-831
- Fixing Series 3 related watchOS crash

### 7.18.1 Builds 824
- Fixed Up Next widget loading the second item incorrectly in some cases
- Fixed an issue where while an add to Up Next animation is running, you couldn't tap the Up Next button
- Accessibility no longer reads the podcast name for an episode when you're on the podcast page

### 7.18.1 Builds 823
- Fix widget not loading

### 7.18.1 Builds 822
- Fix iPad delete account crash
- Update project dependencies and refactor them to be Swift Packages + modernise all the things
- Improve image loading for CarPlay

### 7.18 Builds 821
- Added a way to re-enable old private feeds that might have been turned off when you stopped paying, but you're now paying again. If that sounds like you, check out the settings for that podcast
- Voice over enhancement for episode rows: the app will now tell you which podcast they are associated with

### 7.18 Builds 820
- Added delete account to profile page
- Added episode metadata to lock screen/bluetooth info when available (eg: title S3E22)

### 7.17.2 Builds 819
- Improved the speed selection button in CarPlay
- Fixed an issue where the tab bar could shuffle over and tapping the blank space would crash the app
- Fixed some typo's in settings

### 7.17.2 Builds 818
- Improved the way the watchOS app handles sync failures on initial setup
- Added an option to allow opening links in your browser instead of in app
- Added a 1000 option for the Auto add to Up Next limit. People be crazy, yo.

### 7.17.1 Builds 817
- Fixed an issue with the actions shown on user files being the wrong way round (download for things that are already downloaded, etc)

### 7.17.1 Builds 816
- Added multi-select delete support to the Files section

### 7.17.1 Builds 815
- Fixed an issue with the playback scrubber not working on iPad after a rotation
- Fixed various small padding issues
- Added support for showing embedded artwork on the lock screen
- Fixed some compiler warnings

### 7.17.1 Builds 814
- Fixed the support email link for people who don't have Apple Mail configured
- Fixed a widget related crash

### 7.17.1 Builds 813
- Fixed an issue where some Siri Suggestions were missing artwork

### 7.17 Builds 812
- Fixed a colour issue with filter settings for high contrast themes
- Fixed a bug where changing a podcast in settings might not update the settings on the podcast page
- Fixed an issue where you briefly see default text on various Apple Watch screens before the real text loaded
- Updated dependencies
- Tweak theme colours
- Build 811 didn't upload properly to iTunes, so don't worry you didn't miss anything

### 7.17 Builds 810
- Fixed a Siri related crash and improved Siri intent handling
- Fixed an issue where show notes links could be the wrong colour
- Fixed an issue with episode durations on the widget

### 7.17 Builds 809
- Added what's new information
- Updated colours for high contrast themes as well as fixing no podcast discover button
- Fixed an issue with iOS 14.2 and our new password field on the create account page

### 7.17 Builds 808
- Added 2 new high contrast themes
- Fixed an issue that could cause podcast playback to stall when streaming
- Cleaned up some old themes and fixed a few issues with them including importing new tokens
- Cleaned up how switches look in the app so you don't end up with white backgrounds and white thumbs
- Added release notes

### 7.16 Builds 807
- Rosé theme tweaks
- Various other theme tweaks
- Fix mini player covering filter options

### 7.16 Builds 806
- Updated auto up next limit text to make the behaviours a bit clearer
- Fixed an issue where when tapping to hand off to a HomePod Mini playback would stop
- Fixed an issue where changes you make or user files might not be saved
- Fixed a typo in the release notes

### 7.16 Builds 805
- Added What's New information and release notes
- Added configurable Up Next limit
- Fixed a bug where the Indigo theme was marked as needing Pocket Casts Plus (regression introduced in build 802)
- Fixed the home indicator appearing on the now playing page (regression introduced in build 804)

### 7.16 Builds 804
- Improved volume boost to make voices sound even betterer
- Fixed a potential crash when downgrading to a version where a theme doesn't exist
- Fixed being able to jiggle the colours when creating a filter. I'll miss that bug
- Fixed lots of weird and wonderful issues with the tab bar not being there when you perform too many ninja moves at once

### 7.16 Builds 803
- Removed the accent from Rosé theme assets because something about the Xcode/TestFlight build pipeline really hates them

### 7.16 Builds 802
- Added new theme: Rosé
- Added domain association so that password managers can auto-fill/save properly in our app
- Share links can now be opened straight in the app without needing to open the web page first

### 7.15 Builds 801
- Fixed an issue with Siri Shortcuts no longer working correctly after being renamed

### 7.15 Builds 800
- Lots of small design tweaks to the filter creation process
- Update filter icons
- Fixed some layout issues with various size widgets
- Fixed an issue where tapping a link on an episode card would cause the card to slide up
- Fixed an issue where siri suggestions on the lock screen now playing area might be missing artwork
- Fixed issues with displaying large navigation titles in various parts of the app
- Fixed an issue where in the filter preview incorrect durations would be displayed for episodes

### 7.15 Builds 799
- Fixed an issue where widgets might not load
- Small widget app icon now matches the app icon you choose in Appearance for the app itself
- Tapping on the small widget now opens the app, rather than going to discover or the player, etc.
- Fixed an issue where episode titles could be cut off in various widgets
- Remove workaround added for crashing on iOS 14.2, beta 2
- Keyboard now dismisses on the filter create page if you scroll up

### 7.15 Builds 798
- Added what's new and release notes
- Fixed an issue where multi-select mark as played wouldn't work correctly when one of the selected episodes was the one currently playing
- Fixed an issue with the loading indicator not showing correctly across all devices

### 7.15 Builds 796, 797
- New filter creation flow to make creating filters more intuitive
- New Feature: Intelligent playback resumption
- Fixed an issue where things launched from the player would hang around even after the player had closed
- Fixed an issue that could cause show notes not to wrap
- Fixed an issue where the CarPlay buttons on the now playing screen might be the wrong colour
- Fixed an issue where updating the per podcast playback effects through the player might not update them properly
- You can now tap on the background around episode cards on iPad to close them
- Fixed an issue where labels in Discover might get truncated with the bold accessibility setting turned on

### 7.14 Build 795
- Small CarPlay tweak

### 7.14 Build 794
- Instead of play/pausing to show the now playing tab in CarPlay (which would pause any music you have playing), the app now offers your Up Next and currently playing items at the top of the first tab
- Fixed (hopefully) CarPlay icons being tinted the correct colour for light/dark CarPlay

### 7.14 Build 793
- Added 3 levels of Trim Silence! Mild, Medium and Mad Max
- Fixed an issue that could prevent some Siri Shortcuts from running properly

### 7.13 Build 792
- Fixed typo's on the whats new page
- Widget tweaks (you can now see the podcast name on both medium and large sizes, replaced "Up Next" with time remaining)
- Fixed long press context menus on back buttons in settings, etc being blank

### 7.13 Build 791
- Addded release notes an what's new page
- Fixed the podcast sort order in CarPlay not matching the one you chose on the phone

### 7.13 Build 790
- Widget tweaks and bug fixes
- Fix an issue with pulling down and display of episode cards
- Standardised headers used on various settings pages

### 7.13 Build 789
- Added the ability to zoom into chapter/show artwork by tapping it in the player
- Improved performance of loading large Up Next lists
- Changed min iOS version to 12
- Improved CarPlay light mode support
- Fixed a start-up crash. See, aren't you glad you don't get internal beta's!

### 7.13 Build 788
- Brand spanking new iOS 14 widget!
- Carplay enhancements including linking the podcast from now playing, getting the now playing page to appear on launch and adding a mark as played button and showing chapters when there are chapters

### 7.12 Build 787
- New CarPlay interface for iOS 14
- Fixed an issue that could cause large artwork from an episode file not to load
- Fixed a notification related crash
- Fixed an issue where the overlay buttons on a video on iOS 14 were yellow
- Added workaround for an iOS 14.2 beta 2 streaming bug

### 7.12 Build 786
- Fixed an issue that could cause the buttons and nav bar at the top of the podcast page to be in the wrong position and height
- Fixed iOS 14 issues with the mini player and full screen player when you pull up and down
- Added support for extra large graphical complication...why anyone would pick us for this is beyond me, but you never know!

### 7.12 Build 785
- Added archive all played to podcast page
- Allow filter duration times to go to 1m instead of 5m as the minimum
- Fixed an issue where after a stream fail the app might not be able to resume the stream
- Added video icon to indicate video episodes
- Update to iOS 14 compatible Google Cast version
- Fixed an issue with loading podcast images while the app is in the background
DON'T POST THIS BIT TO PUBLIC SLACKS
- Added support for bundles to all the screens that need them

### 7.12 Build 784
- Re-instated the ability to unsubscribe from a podcast no matter it's paid status
- Fixed the sleep timer background being brown in iOS 14
- Various accessibility fixes

### 7.12 Build 783
- You can perform actions like un-star, un-archive, mark as unplayed and removing downloads
- Multi-select now works for episodes in your custom files section
- You can now re-arrange multi-select actions for Up Next
- Fixed some issues with multi-select ordering when adding to things like Up Next
- Fixed the Up Next drag handle not being visible on iOS 12 and below
- Fixed an issue where "Remote Skips Chapters" wouldn't work in some cases like CarPlay and the lock screen when turned on
- Fixed some issues with text getting cut off on the Apple Watch
- Fixed an issue with some podcasts not having their MP3 chapters recognised properly
- Accessibility improvements
- Switched to the new iOS 13 Scene Delegate APIs
- Fixed some issues with the Profile -> Starred page
DON'T POST THIS BIT TO PUBLIC SLACKS
- Added support for category ads and paid podcasts

### 7.11 Build 782
- Fixed an issue with select all mult-select ordering
- Fixed an issue where the show notes page could end up under the notch when you come back from a link

### 7.11 Build 781
- Fixed an issue with re-arrange handles on iOS 12
- Added plist entry to explain iOS 14 networks usage
- Updated the filter chip formatter to be the same one as on the edit page

### 7.11 Build 780
- Added the ability to filter by duration in an Episode Filter
- Added the ability to sort by duration in an Episode Filter
- Added play all option to Episode Filters
- Fixed an issue that could cause some chapter artwork not to be parsed (for example the AppleInsider podcast)
- Various small tweaks and adjustments including styling of stepper controls
- Added a way for the support team to trigger sending of purchase receipt
- Added a dedicated Pocket Casts Plus page that explains a bit more about what it is, and also a few new callouts

### 7.10 Build 779
- Fixed an issue where the Up Next list flashed on re-arrange
- Fixed an issue with multi-select move to top/bottom
- Added support for user uploaded files in up next multi-select
- Other small tweaks and fixes

### 7.10 Build 778
- Lots and lots of multi-select fixes

### 7.10 Build 777
- Multi-select bug fix
- What's new page text update

### 7.10 Build 776
- Added multi-select to listening history page
- Added support for iOS multi-select gesture to Up Next page
- Other small tweaks and fixes

### 7.10 Build 775
- Lots and lots of multi-select changes and improvements

### 7.10 Build 774
- Added multi-select support to the podcast and episode filter pages (coming to more places soon)
- Long press (or use the menu option) to enter multi-select. Long press again for selecting all below/above if you need that
- Fixed an issue that could cause BT artwork not to load reliably
- Fixed an issue where video playback would freeze when switching from streaming to a downloaded version
- Added per device volume controls when casting to a multi-speaker group
- Fixed a Google Cast issue that could cause the play button to do nothing in the app

### 7.10 Build 773
- Added missing database migration

### 7.10 Build 772
- Slightly redesigned podcast page, including per podcast show/hide archived settings
- New setting in Settings -> General so you can choose what you want the default for show/hide archived to be (will also prompt you when you change it to apply to all if you want)
- Fixed a crash that could occur when opening an episode share link
- Fixed a different crash that could occur when opening a podcast share link
- Fixed an issue that could cause items in the Up Next list to be hard to drag up and down right at the beginning of the drag
- Improved handling of auth token expiry
- Added [REDACTED - Project Thunderdome] support

### 7.9.1 Build 771
- Fixed issues with watch background refrœesh
- Fixed an issue that could cause podcast images to not appear on car stereos (and other devices)
- Fixed an issue with our crash logger, not err, logging crashes.

### 7.9.1 Build 770
- Revert CarPlay change since it didn't work in testing
- Expanded support for server cache headers in discover
- Added release notes
- Minor wording changes
- Added more login around watch login errors

### 7.9.1 Build 769
- Testing having smaller speed steps in CarPlay
- Fixed an issue where the watch app might show the wrong dates in an episode list
- Fixed an issue with the Radioactive theme interfering with iPad trackpad scrolling
- Minor text changes in settings

### 7.9.1 Build 764, 765, 766, 767, 768
- Fixing apple watch restoration issues

### 7.9.1 Build 763
- Download page now shows download icons to match the rest of the watch app
- Fixed an issue with the play/pause buttons being different sizes in the watch app
- Added a warning on the watch when you clear an Up Next queue that has more than 2 episodes in it (to match the phone)
- Another fix for the watch app loading to not the player page when playing

### 7.9 Build 762
- Fixed an issue that would prevent streaming of custom cloud files

### 7.9 Build 761
- Fixed a limit issue on the Files controller page
- Hopefully fixed the issue where when playing from your phone, the watch app wouldn't open to the player. Again. Again.

### 7.9 Build 760
- Fixed a potential crash that could happen when using the move to top/bottom options in Up Next
- Tweaked the way we display time remaining in the phone source on the watch
- Hopefully fixed the issue where when playing from your phone, the watch app wouldn't open to the player

### 7.9 Build 739 -> 759
- Fixing Series 2,3 watch crashing issues

### 7.9 Build 738
- Fixed an issue with showing chapter names for something you're playing on your phone, in the watch app
- Hopefully fixed the issue where the watch app would open one screen below the player instead of on the player
- Fixed an issue that would have prevented streaming custom episodes
- Fixed an issue with loading now playing info that could cause it to be missing or the app to crash

### 7.9 Build 737
- Added "Go to podcast" option on the Episode page on the watch, for when you're browsing a watch episode
- Fixed issues with data sizes being transferred from phone -> watch
- Fixed issues with the watch app attempting to refresh too often
- Tweaked 38mm and 40mm now playing screen
- Added fixes for syncing large podcast collections to the watch
- Fixed an issue that could cause the watch not to sync playback history information with your account
- Fixed an issue where the email compose window and safari links couldn't be interacted with while in the Radioactivity theme

### 7.9 Build 736
- Added episode details button to the 3D touch options on the now playing watch screen
- Improved watch app performance
- Fixed an issue where some of the icons on the Appearance page icon previews were low res
- Added scanlines to the Radioactivity theme preview icon. You gotta give the people what they want!
- Built with Xcode 11.5. Hopefully you can't notice. That's not meant to be a user facing thing.

### 7.9 Build 735
- Removed some of the debug logs we don't need anymore
- Fixed an issue that could cause episodes in Up Next to be duplicated
- Fixed an issue where the player could be intialised when it didn't need to be, possibly causing battery life issues
- New Watch player design with permanent progress bar. Thanks for all your feedback on this one
- New 3D touch options to quickly go to the player/main menu on Apple Watch
- Fixed an issue that could cause the watch app to crash with larger podcast collections
- Tweaked watch image cache so that it uses less memory
- Fixed accessibility issues with the share podcast list function
- Fixed an issue where after an episode search the keyboard could cover the mini player, even after you choose to play an episode
- Fixed an issue that could cause the player on watchOS to take a second or two to open
- Added podcast sort option when browsing podcasts on your watch (3D touch to access)
- Fixed a bug where the app might report that it's streaming or playing when it's not doing either

### 7.9 Build 734
- Yet another Series 3 watch crash fix...hopefully the last one required!
- Fixed a different reported watchOS crash
- Fixed an issue that could cause the app to create a player when it didn't need to
- Fixed a background issue that could cause excess battery use
- Tweaks to Plus pages inside the phone app
- Fixed a colour issue with the buttons at the top of the podcast page
- Fixed an issue where the app could report that playback has failed for an episode that just got downloaded (and in a few other cases)
- Added accessibility labels for the share podcast list feature
- Fixed accessibility issue with the subscribe button

### 7.9 Build 733

Watch Changes:
---------------
- The app should now background refresh and keep itself up to date
- Added voice over labels to elements that were missing them
- The app mostly opens to the right page now while playing
- Tweaked now playing page design
- Implemented sorting of custom user episodes
- Finished auto download up next implementation
- Hopefully fixed the series 3 crash once and for all
- Fixed star/unstar'ring episodes not updating the episode correctly
- Made log file smaller as it was taking too long to transfer when needed

Phone Changes:
---------------
- Fixed the stats page being cut off at the top
- Fixed the podcast grid selection control not showing the selected item correctly
- iPad version (and phones that don't support it) no longer show watch settings
- cmd-f can now be used on pages that have search to quickly get to that search from a keyboard
- Fixed some accessibility issues with rotor actions as well as Up Next dismiss

### 7.9 Build 732

Known Issues:
---------------
- The watch app seems to open to the screen below Now Playing when you play something from your phone. It's stubborn, I'll tells ya that
- The watch app is not yet fully accessible for Voice Over

Watch Changes:
---------------
- Implemented background downloads. In theory you now don't have to keep the app awake to have a download complete, yay!
- Fixed an issue where custom episode images wouldn't load on the episode page
- Hopefully fixed the crash Series 3 owners are having when trying to access the phone source section
- Moved play next, play last higher up the episode actions list
- Watch app no longer shows archived episodes in podcasts, so you can get to the ones you actually want to play
- Improved the ability of the watch to stay in sync with your account/your phone

Phone Changes:
---------------
- Fixed issues with the Radioactivity Theme messing with the Chromecast dialogs
- Removed Google's garbage Chromecast dialogs and finally made our own
- Fixed episode cards opened from Up Next sometimes having wrong/un-readable colours
- Added what's new in 7.9 popup, to err, tell you what's new in 7.9

### 7.9 Build 731

Known Issues:
---------------
- Background downloads for the watch haven't been implemented, so you need to keep the watch app awake manually, otherwise downloads will fail
- Turning on auto download in phone settings for the watch is not recommended, this isn't implemented properly yet
- When using the Radioactive theme, sometimes windows that pop up (like for chromecast) aren't tappable
- The watch app is not yet fully accessible for Voice Over
- While the phone version is fairly stable, the watch version may crash or have other odd bugs we haven't found yet

Watch Changes:
---------------
- Fixed an issue where the source selector page would be the first page the app opens when it's launched
- Updated watch auto download settings
- Improved the ability of the watch app to stay in sync with your account and phone
- Hopefully fixed a crash on Series 3 Apple Watches...I wasn't able to verify this though...
- Improved the way images are loaded
- Improved the design of the now playing screen
- Fixed an issue that could cause the watch not to have any skip times set, and so pressing skip wouldn't do much
- Updated Episode card design
- Updated the nothing playing screen and fixed bugs with left over controls being on it
- Fixed an issue where the podcast name would be blank for things you're playing on your phone
- Various other design fixes and improvements

Phone Changes:
---------------
- Improved themeing components in various places including the segmented control that lets you choose grid size for podcasts
- Fixed an issue that could cause the now playing info (that goes to Bluetooth and other devices) to not be set
- Fixed the arrangement of the Done vs Select buttons in Up Next


### 7.9 Build 730
- Fix a watch crash to do with lifetime plus membership
- iOS route picker now has an accessibility label
- Changed the way we load images on the watch to make it faster and hopefully less crashy
- Moved Server package notifications off the main thread
- Added a delete confirmation for watch downloads
- Improved the way the watch app syncs, it should now have more up to date data more often

### 7.9 Build 729
- Crash fixes for Apple Watch

### 7.9 Build 727, 728
- Fixed icon plist entry, please let our build through Apple

### 7.9 Build 726
- Added 3 new free icons: Indigo, Pocket Cats and Red Velvet
- Improved syncing of settings from phone -> watch
- Fixed accessibility issue with the star option on the episode page, you should now be able to tell if an episode is starred or not
- Remove radioactive overlay when watching video full screen
- Fixed an issue where pressing pause/play in a Picture in Picture window would cause the playback speed to reset to 1x
- Implemented the effects icon for the watch now playing screen
- Imported latest colours spreadsheet
- Tweaked layout of the watch podcast episode rows

### 7.9 Build 725
- Added better support for Apple crash reporting

### 7.9 Build 724
Phone changes:
- Improved trim silence algorithm (it was set to be super agressive, oops)
- If you open the watch app before tapping on the button to send a support email, it will now attach a watch debug log as well
- Added share podcast option to now playing screen on the phone

Watch Changes:
- Implemented chapter skipping
- Episodes playing show chapter name if there is one
- Restored tap on podcast name to get progress bar
- Improved speed of downloads
- Lots of improvements to episode rows (design changes, download progress, things getting cut off, displayed info, etc)
- Lots of fixes and improvements for the episode card
- App now auto opens to the now playing phone screen if launched by watchOS for that purpose
- Performance improvements
- Improvements to filter list page
- Added haptics to refresh buttons
- Added haptics to episode card action buttons
- Improvements to the watch loading plus subscription status
- Phone browsing interface now matches watch browsing interface
- Removed source label from Now Playing page

### 7.9 Build 723
- Moved some refresh stuff off the main thread
- Fixed an issue where your watch assets wouldn't load and the app would crash

### 7.9 Build 722
- Tokenized and themed more of the app then ever before
- Fixed an issue that could cause the watch app to lock up when you activate it
- Tweaked some things in the watch app and fixed some custom episode issues
- Fixed some rotation and dialog issues with the Radioactivity theme
- Switched to storing your password and tokens more securely. Please let us know if you end up logged out or see any other weirdness!
- Implemented the first pass of auto download Up Next for watch

### 7.9 Build 721
- Watch App is now way better (too many tweaks and features to list here. Yes I am that lazy, but luckily Shilpa isn't, she's on fire!)
- Added icon for Radioactivity
- Changed refresh server timeout to 60s
- Added clear button to search on podcast grid/list and discover pages
- Fixed progress colours for Radioactivity theme on mini player
- Fixed an issue where episodes released recently but with older published dates would be archived
- Fixed an issue where pocket casts links wouldn't work in the inbuilt browser used by Pocket Casts (I know, that's some inception level stuff right there)
- Fixed a syncing issue where episodes could be synced with progress but still start from the beginning anyway

### 7.9 Build 720
- Added Radioctivity Theme
- Many watchOS changes
- Forgot to update this change log properly. Too bad too sad.

### 7.8.5 Build 697
- Added support for custom file deleting when you're offline
- Improved support for iPad pointing devices
- Fixed an issue where when you're airplaying to a HomePod sometimes you have to press play more than once to get it to play

### 7.8.5 Build 696
- Added more logging so we can tell exactly why a refresh fails (when and if it does)
- Fixed a crash that occurs when you use the accessibility rotor action to archive an episode in a list
- Fixed an issue where custom episode progress wouldn't be displayed on the mini player
- Fixed an issue where playback errors could be shown for an episode you just started downloading

### 7.8.4 Build 695
- Fixed an issue where the inactive archive setting for a podcast would show the global one selected in the selection popup

### 7.8.4 Build 694
- Fixed an Airplay playback issue

### 7.8.4 Build 693
- Fixed an iPad issue where some of the UI could get wonky when the app resumed from being backgrounded (missing filters, super weird long filter name, etc)

### 7.8.4 Build 692
- Fixed an issue that caused the swipe menus on the Files and Listening History pages to not work in the previous few beta builds

### 7.8.4 Build 691
- Fixed an issue where seeking a downloaded episode while it's paused could cause weird issues
- Fixed an issue where the artwork on the player page could flash while reloading.

### 7.8.4 Build 690
- Fixed an issue where after seeking the progress indicator for a podcast could stop moving
- Fixed the top item in featured lists not having a label and instead showing an empty pill. Don't do drugs kids, even empty pills. It's a slippery slope.

### 7.8.4 Build 689
- Improved OPML import support. You should now be able to import large OPML files to your hearts content.

### 7.8.4 Build 688
- Fixed an issue where if you set the Skip Last setting on a podcast, and chose the "End of Episode" sleep timer option the app would ignore your sleep timer
- Fixed a few rare (but important) crashes

### 7.8.4 Build 687
- Improved the way swiping to archive works in various lists. This should now be faster and easier.
- Fixed an issue where if you left the show notes page up and left the app, it could appear blank when you come back
- Improved accessibility of the search element on the podcast list page
- Fixed an issue with accessibility where swiping through podcasts could cause VoiceOver to read them twice
- Tweaked some of our Siri actions

### 7.8.3 Build 686
- Fix episode share link URL being wrong

### 7.8.3 Build 685
- Fixed a different chapter parsing crash. And who said parsing chapters wasn't endless fun?!

### 7.8.2 Build 684
- Fixed an issue that could cause the app to crash while parsing chapters

### 7.8.1 Build 683
- Fixed the Siri suggestion shortcut not working in some cases

### 7.8.1 Build 682
- Added support for asking Siri to play podcasts for you. "Hey Siri, play The Daily on Pocket Casts" and similar phrases should work.
- Improved Siri previous and next chapter commands, they should now work way betterer.
- Pocket Casts way more likely to appear in the Shortcuts app now without having to swing rubber chickens around to get it to happen.
- Fixed the colour of the ticks in Discover. I know, lots of you were losing sleep over them. You're welcome.
- Fixed the indenting on the custom file add page. Same as above, I know.
- Fixed the padding of the end sleep timer button. THREE FOR THREE!
- Fixed a typo in the first run user tour.

### 7.8.1 Build 681
- Added the ability to tap on the tab you're already on to go to the top, and in discover trigger search
- Fixed an issue with CarPlay where it could lock up and or refresh too often
- Fixed an issue where your skip last time wouldn't be imported for a podcast you'd subscribed to on another platform
- Improved effects panel design
- Improved progress line design
- Improved readability of the controls on the video player overlay

### 7.8.1 Build 680
- Tweaked mini player progress line colours
- Fixed an issue where Up Next time remaining label was getting cut off on smaller width devices
- Added stats collection and reporting for outro skipping (combined with intro skipping and renamed to auto skipping)

### 7.8.1 Build 679
- Added Skip Last setting that you can set on podcasts you want to skip the end of
- Fixed an issue where when finishing a user file and having a sync account it would be not marked as played, but instead be 0s from the end
- Added trial expired dialog
- Added 7.8.1 release notes
- Fixed an issue where if you leave a podcast page open, it can cache old settings for that podcast and not show you updates to them

### 7.8.1 Build 678
- Fixed an issue that could have caused an auto download to go over cellular even though it wasn't meant to
- Added long press option to video player skip forward to match the audio player
- Fixed an issue with playing two videos in a row, where you would have to play/pause to get the next one to play properly
- Tweaked the now playing info (lock screen, CarPlay, etc) to show the published date of the episode you're listening to
- Fixed an issue where if you had the effects or sleep timer up, the player was unable to be closed by the app

### 7.8.1 Build 677
- Updated video player design to make things like skipping easier
- Fixed an issue where the open player automatically could be a bit agressive about, well, opening the player automatically
- Added Listening History to CarPlay
- Fixed issues with having the opposite theme in iOS vs Pocket Casts and the status bar dissapearing/nav bars being the wrong colour
- Fixed issues with the player not responding correctly to theme changes
- Added extra notification actions to see how iOS handles them. If they work well, we won't add any settings for them
- Updating the way we handle chapter parsing to fix some podcasts chapters weren't appearing for (for example the German podcast Audio Dump)
- Fixed an issue where when the podcast artwork changes, the colours the app has stored for that podcast don't
- Tweaked the discover page to make titles and descriptions more readable
- Fixed a sync issue, as well as a seeking issue where the app was trying to seek before the player was ready to do so. The main way you'll see this is when something you've played on another device syncs to yours, it will no longer look like it's at 0:00.
- Fixed an issue where if a share link loaded too quickly (LOL, NBN woes) it wouldn't open

### 7.8 Build 676
- Fixed a few crashes
- Implemented legacy bluetooth mode to try and help those poor struggling BMW owners out
- Tapping a time in show notes now jumps to the player page
- Fixed some heading alignments
- App now refreshes when using CarPlay (for those that leave it plugged in all day)
- Added promo code support

### 7.7 Build 675
- Fix custom episode related crash
- Fix "select all below" in Up Next sometimes, well, not selecting all below (ditto for above)

### 7.7 Build 674
- Finalise for release

### 7.7 Build 673
- Fixed some UI glitches that could happen when opening the app from the Today Widget or app icon shortcuts
- Fixed a title alignment issue when opening some podcasts
- pktc://subscribe links no longer automatically subscribe you to a show, they now pop up the podcast so you can choose whether you want to play stuff, or hit subscribe
- Fixed a database related crash
- Fixed an issue with opening share lists that have podcasts that are private or no longer exist

### 7.7 Build 672
- Added support for creator collections in the discover section
- Fixed an issue where sorting an unsubscribed podcast would cause most of the things on the page to no longer work
- Fixed an issue where your listening stats could appear to be larger than they should be
- Implemented a new user tour
- Fixed some theming related issues on the filter page
- Upgraded to Xcode 11.3
- Added version 7.7 release notes

### 7.6.1 Build 671
- Fixed a chapter related crash
- Fixed some issues with colours in the episode card and networks section
- Fixed an issue where unsubscribing from a podcast would still count it against any filters it's in
- Fixed a typo in the player tour
- Fixed some issues with rotation of the new popup cards in the player

### 7.6.1 Build 670
- Accessibility fixes for the player section
- Fixed crash when long pressing in the Profile -> Downloads Section
- Fixed incorrect podcasts being queued sometimes in Profile -> Downloads long press, Play all from here.
- Fixed an issue where the podcasts you've selected for push notifications might not get saved to the server properly

### 7.6 Build 669
- Fixed a crash caused when using multi-select to remove episodes from Up Next
- Fixed a minor colour issue on the change email page

### 7.6 Build 668
- Fixed an issue with which tab is selected when switching between playing episodes
- Improved Siri Shortcuts including the previous and next chapter shortcut

### 7.6 Build 667
- Fixed an issue where you couldn't share custom episodes into the app if Up Next was open
- Fixed a discover search issue where some of the text was unreadable on some themes
- Fixed an issue that surfaced when seeking repeatedly in AirPlay 2 streams (eg: HomePod, etc)
- Fixed an issue where sometimes the player tabs could show the wrong content
- Fixed an issue where if you pull up to get Up Next, opening and closing episodes would cause a weird glitch transition at the top of the page
- Lost our cool build number. To think we could have had build 666 on Friday the 13th. You miss 100% of the shots you don't take people!

### 7.6 Build 666
- MU HA AH AHAHAHAH. Sorry just saw the build number
- Minor wording chages to the What's New Tour
- Fixed an issue with pulling down Up Next slowly
- Fixed an iPad crash
- Fixed an Up Next related crash
- Design tweaks for podcast settings pages
- Fixed an issue where your navigation bar could go walkabout for a while

### 7.6 Build 665
- Improvements to multi-select in the Up Next list
- Up next tour implemented
- Fixed a custom episode related crash
- Fixed some issues with the player toolbar
- Fixed an issue with the Up Next list triggerring the tap event after a scroll
- Added a warning if you have warn when not on WiFi on and you multi-select and choose to download off WiFi

### 7.6 Build 664
- Added player tour for people upgrading to the new version
- Whats new text updated
- Added 7.6 release notes
- Icons on the player toolbar now update more reliably
- Fixed an issue where adding a custom file to Up Next showed the no artwork artwork when animating in
- Fixed user episode colours for Indigo theme
- Added a new shortcut: tap on the currently playing chapter to jump back to the now playing tab
- Fixed some iPad issues with the Up Next page
- Attempting to stream episodes in Up Next now comes with a warning if you have the warn setting turned on
- Fixed an issue with swiping to remove from Up Next then scrolling up and down
- Fixed an iPad issue with resuming from sleep on the player

### 7.6 Build 663
- Changed player to have a close arrow instead of a drag handle. This also fixes the bug a few of you have reported to us about tapping on "Notes" only to have the player close
- Tweaked the size and spacing of various paging dots we use in the app
- Tweaked the layout of the player page a tiny bit
- Sleep timer dialog is now a more reasonable width on the iPad

### 7.6 Build 662
- Whats new page added for the 7.6 release
- Added swipe to remove from Up Next
- Fixed weird side swipe to dismiss player bug
- Fix issues with chapter and now playing cell progress jumping when the view first loaded
- Fixed issues with Up Next drag handle tinting
- Fixed crash when selecting download of a user file from the Up Next page
- Up Next page now shows download progress/status more accurately
- Fix long pressing on the re-arrange icon in Up Next causing that episode to play

### 7.6 Build 661
- Allow Up Next screen to be pulled down to dismiss
- Fixed text aligment on the Up Next page

### 7.6 Build 660
- Indigo Theme tweaks
- Player design tweaks
- Fixed sleep timer animations
- Up Next disable theme change on nav bar long press
- Accessibility fix that allows the mini player artwork to be tapped

### 7.6 Build 659
- Implemented multi-select in Up Next
- Fixed various iOS 12 issues
- Implemented tap on chapter name to go to chapter
- Tapping on a chapter cell if you're not playing now starts playing
- Switched back to the offical Google BottomSheet component now that they added that variable for us (so kind!)
- Fixed the paper cut colour issue on the show notes page
- Fixed icon tint color in the Option Picker
- Fixed location of the chapter link on the player artwork and made it tappable
- Tweaked sleep timer dialog
- Tab line now animates if you pull at the edges
- Fixed an issue where the app could lock up for a bit when resuming from sleep/changing playing episodes, etc. It's not easy being an app, ok, just give it a break.

### 7.6 Build 658
- Fixed subscribe button colors
- Updated to latest token spreadsheet
- Fixed an issue where the player could skip over an episode in your Up Next list
- Episode and User Episode cards now always open dark when done from the Up Next list
- Fixed an issue where an archived episode could be in your Downloads section until the next app launch

### 7.6 Build 657
- Performance improvements to the new player
- Implemented feed add polling (to make adding feeds more reliable)
- Added logging to try and locate Up Next issues
- Modified how close Show Notes and Chapters were to the top of the screen
- Fixed the token used for the discover sponsored item
- Fixed more episode scrubbing issues

### 7.6 Build 656
- Fixed the shelf re-arrange logic
- Fixed an Up Next related crash
- Fixed Up Next animation not running in some cases
- Fixed Show Notes background colour not being kept up to date
- Implemented colours on the Effects panel
- Tabs are now adjusted on smaller devices/screen widths to fit
- Fixed route icon dissapearing sometimes in the re-order page
- Tweaked shelf design, including what the done button does, and when you can drag vs can't, also the design
- Hide the podcast name on scrub, instead of the episode name above it

### 7.6 Build 655
- Fixed a download all related crash
- Fixed issues with using the timeline scrubber in the new player
- Adjusted alignment of the skip buttons to match the design
- Fixed filter titles being white bars in some themes
- Pulling up Up Next no longer requires as much pulling
- Fixed the alignment of icons on the shelf

### 7.6 Build 654
- First build of 7.6
- New Indigo Theme added
- Up Next/Player redesign
  - player button shelf is now user configurable
  - show notes and chapters moved to make them easier to get to
  - Up Next can now be accessed directly from the mini player, or from the player (also supports swiping up like before)
 - Fixed an issue with syncing played episodes from other devices
 - Fixed an issue with custom episodes in Up Next being skipped
 - Fixed an issue with audio interruption handling
 - Added sort by episode length on the podcast page
 - Scroll bar colours now match the theme you're on

### 7.5.4 Build 653
- Fix for CarPlay connection issue

### 7.5.3 Build 652
- Another syncing fix. Cheers to the people who reported this and helped us track it down!

### 7.5.3 Build 651
- Added extra logging in case we need it to track down an issue with episodes becoming un-archived

### 7.5.3 Build 650
- Attempted fix for some syncing issues we've been working with people on (archived episodes coming back)
- Added support for chapters in a streaming custom file (eg: one you upload into the app)
- Fixed an issue that could cause your files to be duplicated
- Fixed a crash on importing an invalid chapter URL and then attempting to tap on it
- Fixed the podcast switch colours in podcast settings
- Fixed a stats issue that we fixed server side, but it doesn't hurt to have it in the iOS code too :)

### 7.5.2 Build 649
- Fixed an issue where the mini player was flying too close to the sun (separating from the player and seeking FREEEDOM)
- Fixed issues with the way our filter edit options pop up
- Fixed an issue where the video player didn't have a background or rotate
- Added what's new dialog for DARK MODE
- Fixed issue where the stepper cells we use (the [-  +] things) were cut off in iOS 13
- Added the ability to clear your listening history

### 7.5.2 Build 648
- Fixed a syncing issue introduced in the previous version to do with legacy sync dates
- Fixed an issue where syncing a podcast could cause the app to unsubscribe from it
- Added better support for unsupported custom file types
- Added the ability to show error messages for custom episodes when you tap on them
- If you manually toggle themes and it's to one the system isn't currently in, the app now turns off the follow theme setting so that it doesn't get changed back on your automatically

### 7.5.2 Build 647
- Added support for dark mode
- Lots of syncing changes and improvements
- Added group by starred to podcasts

### 7.5.1 Build 646
- Fixed an issue where the upload icon could show on the files page when nothing was uploading

### 7.5.1 Build 645
- Fixed an issue with lifetime subscriptions showing as -34 years free
- Fixed a visual issue where your chapter title and episode title could overlap
- Fixed the login page on the iPhone SE
- Fixed an issue where episodes that had just been archived could be auto downloaded
- Added long press options to the Files page
- Improved accessibility on the Appearance page
- Fixed some theming and visual issues
- Syncing improvements and fixes
- Fixed a possible crash when playing an unsupported file type
- Fixed an issue with adding podcasts to filters

### 7.5 Build 644
- Adjusted IAP purchase flow and screens based on feedback
- Added links to privacy policy and terms of use inside the app

### 7.5 Build 643
- Fix Up Next syncing bug to do with custom user episodes
- Fix search field styling on podcast page when Electricity theme was chosen
- Fixed remote commands being logged after the command had taken place, making it harder to read the log

### 7.5 Build 642
- Added final version of release notes
- Removed double tap to cycle theme testing shortcut
- Changed 'Latest Releases' to 'Latest Release'
- Fixed an issue with the subscription queue not being cleared correctly
- Cleaned up logging of subscriptions in the app
- Changed minimum background refresh time from "Do it as often as you can" to "30 minutes". This is an indicator to iOS as to how often is too often when it comes to it wanting to refresh our app. This figure should be a bit gentler on our servers without affecting people getting new episodes, etc. Only affects the app when it's closed, not when you open it or when you get push notifications.

### 7.5 Build 641
- Improved handling of upgrade process for gifted users
- Fixed Podcast and Discover pages scrolling to the top by themselves sometimes
- Fixed an issue where you can come back from search and be stuck
- Added draft version of 7.5 release notes
- Fix for files that have empty strings in their titles
- Fix for the save button being missing in some occasions in the File Edit dialog
- Tweaks to some button disabled states + fonts

### 7.5 Build 640
- Fixed an issue where you could be shown the plus info card when you already have plus
- Added icons to file settings page
- Improved Appearance page design implementation
- Fixed colour issues with the discover subscribe buttons
- Fixed an issue where if you scroll really fast you could get the search bar to half show
- Fixed an issue with subscription dates
- Updated design of Discover Featured section to match the Point Bits(TM) reference

### 7.5 Build 639
- Lots more theme related fixes (missing filter numbers, mini player icons, and lots more)
- Improvements for sign in and upgrade flows
- Improved handling of failed receipt validation and purchases in general
- Replaced Apple's search with our own for the Podcast List and Discover pages. Means it's now fully themeable
- Added lock icons to files settings page for non plus users as well as tap for more info
- Fixed files with embedded image locking only colors
- Fixed files without embedded image locking the whole artwork section
- When the subscription is completed (either successfully or cancelled) the user returns to the original screen on which they tapped a locked feature
- All view controllers that have locked features now listen for the subscriptionUpdated notification and unlock features if the subscription status changed

### 7.5 Build 638
- More theming fixes including new illustrations for sign up
- Added correct upload icon + icons missing from File Settings
- Fix crash when tapping on release notes in About page
- Fix not being able to edit an existing image for a custom file
- Design fixes on the About page
- Fix for app showing negative expiry times
- Fix an issue where the app could send the server multiple purchases in a short period of time
- Fix for issue where you'd still have files showing as uploaded to your account after your Plus had expired
- Fix for the Google Cast icon not being tinted correctly in some cases

### 7.5 Build 637
- Fixed issue with status bar colour
- Fixed some lists in discover not opening
- Implemented Google Cast support for custom files you've uploaded to your account

### 7.5 Build 636
- Shiny new about page 😍
- Fix for long press play all crash on some pages
- Fixes for seeking in large video files
- Fixes for navigation bar colours in sign in flow popups (and a few other places, but not for filters)
- Fixes from Joe's feedbacky document thingy
- Added debounce to remote skip events to try and fix some bad BT controllers sending more than one at a time

### 7.5 Build 634, 635
- Updated the terms of use page for small phones, dark mode, etc
- Added whats new dialog. You'll see this when you update to this version. (New users won't, only people who have upgraded)
- Fixed an issue where you could be asked to sign in but you already were
- App now clears old server tokens and passwords out of Keychain on a clean install
- Fixed the layout of the subscription cancelled page
- Fixed issues with table cell selection
- Fixed issues with the colour of the Filter title
- Themed the top buttons in the player
- Themed the overlay close buttons in the player
- Added a new no files page with an explanation of how to add files
- Fixed password field having no prompt text and the text below it being unreadable
- Fixed issues with custom episode and image loading
- Fixed some memory issues
- Improved accessibility of all the new screens we've added
- Removed the legacy 1Password extension
- Fixed issues with the subscriptions page timing out
- Long pressing the navigation bar now toggles between light and dark. App remembers which light and dark theme you last picked.
- For now you can still cycle themes for testing by double tapping the nav bar
- Fixed issues with subscription pricing not appearing
- Improved theming of profile page
- Fixed some version numbering that was confusing App Store Connect

### 7.5 Build 633
- Themed the mini player
- Themed the profile page
- Tweaked some things in the player, mini player and episode cards
- Themed the profile progress view
- Replaced countdown with expiry date when you have more than 30 days of non-renewing Plus left
- Fixed go to podcast not working in player
- Other minor tweaks
- Imported latest theme spreadsheet colours

### 7.5 Build 632
- replaced default delete with custom one for files
- fixed some items in discover not being tappable
- player: fixed route picker tinting and y position
- player: fixed sleep timer not getting updated with everything else
- player: fixed the show notes button dissapearing when it shouldn't
- fixed change password current password field being the wrong colours
- fixed the status bar colour being wrong on the complete purchase page
- added proper user agent to API calls
- minor text changes Martine made us do
- fixed themeing issue on create filter and editing filter options
- fixes issues with logging out when you have custom files

### 7.5 Build 631
- Fixed various theming issues (pink player in extra dark, and other colour changes courtesy of Joe)
- Fixed two crashes (thanks to our new testers for helping us find these!)
- Embiggenned the player icons (the action ones at the bottom)
- Learn more links when upgrading to Plus should now work (though the page they load doesn't exist yet)

### 7.5 Build 629, 630
- Lots of fixes, will list these out in future update notes

### 7.5 Build 628
- First TTF release TestFlight release!

### 7.4 Build 627
- Fixed an issue where re-arranging multiple Up Next items at once could sometimes result in weird ordering.

### 7.4 Build 626
- Added haptic feedback to Up Next re-arrange
- Fix re-arrange crash introduced in previous build

### 7.4 Build 625
- More drag and drop tweaks for Up Next
- Playback crash fix

### 7.4 Build 624
- Fixed long press action being broken with the Up Next sorting changes
- You can now tap with another finger while dragging something in Up Next to move more things at once
- Minor wording fixes in the help debug email

### 7.4 Build 623
- Fixed an issue that could cause podcasts you aren't subscribed to, to be missing sync information

### 7.4 Build 622
- Fixed issues with shortcuts causing UI glitches
- Added a shortcut for opening and closing the player
- Reworked Up Next drag and drop to work correctly with iOS 13
- App now hides status bar when playing full screen video
- Added logging for streaming failures

### 7.4 Build 621
- Fixed an issue where if a lot of actions were taken since the last sync, some of them wouldn't be synced
- Fixed an issue where a stop command from a Bluetooth device could wipe your Up Next
- Fixed play all warning reporting higher numbers than would actually play

### 7.4 Build 620
- Added keyboard shortcuts for iPad users
- Added logging for database errors to debug log
- Added code to cleanup from an error in a previous build

### 7.3.2 Build 619
- Fixed rows showing "0m left" when there's less than a minute to go
- Fixed an issue where episode durations might not be updated properly

### 7.3.2 Build 618
- Fixed an issue found while testing the previous build

### 7.3.2 Build 617
- Fixed an issue that could cause items in your listening history to be duplicated
- Updated the support email address you get when there's no email client configured on your device

### 7.3.2 Build 616
- App now applies auto-archive limit settings sooner than the next time it refreshes
- Play all now warns you about clearing your Up Next list
- Fixed an issue where sorting oldest -> newest and grouping by seasons would still leave the latest season at the top
- Fixed a visual issue when pulling down on the full screen player
- Fixed an issue that could cause podcasts you'd subscribed to on other devices not to be added during a sync

### 7.3.2 Build 615
- Fixes an issue introduced in the previous build where the time sometimes wouldn't tick along (making things like skipping, progress, etc not work properly)

### 7.3.2 Build 614
- Fixed an issue where the app sometimes wouldn't show where an episode was up to (eg: shows 0:00 but is actually at 23:11)
- Improved the discover section didn't load screen
- Updated project dependencies (including Google Cast, let us know if you have any new issues with that!)

### 7.3.2 Build 613
- Improved accessibility on the sign up page, episode cells and other parts of the app
- Changed the word "Downloaded" to "Downloads". I know, I know, you're in supreme awe of my programming skills. Admit it.

### 7.3.1 Build 612
- Fixed a subscribe link crash
- Fixed a crash related to the player page and how it updates when the app comes back into the foreground

### 7.3 Build 611
- Added more detail logging to look into sync errors

### 7.3 Build 610
- Fixed an issue where episodes starred on a podcast page wouldn't look starred in the list after a scroll
- Fixed an issue where the discover section might be cached for too long
- Fixed an issue where Season numbers bigger than 9 would be sorted wrong
- Fixed some crashes

### 7.3 Build 609
- Fixed an issue where sometimes chapters wouldn't appear in the player straight away
- Fixed an issue where "%i" could crash some Mazda and Nissan Stereos with shows like "99% Invisible"
- Added extra logging to support requests to help diagnose future issues
- Added support for showing sync failures on the profile page
- Fixed an issue where if the very first time you sign in syncing fails, a loading spinner remains on screen forever

### 7.3 Build 608
- Fix a Siri Shortcuts related crash
- Fixed a syncing issue introduced in an earlier 7.3 beta

### 7.3 Build 607
- Fixed an issue where changing chapters would sometimes change to just near the chapter causing some weird UI glitches
- Fixed an issue where episodes that were waiting for WiFi didn't get unqueued when archived or marked as played
- Added waiting for WiFi message to the episode card
- Fixed no episodes message not showing up when grouping was turned on for that podcast
- Fixed a syncing issue where episodes played on a different device could be overwritten with old status from another device

### 7.3 Build 606
- Added some new Siri actions to extend your sleep timer, play all in a filter and open a filter
- Fixed an issue where trying to download an episode that had just started streaming might not work properly
- Fixed an issue where unsubscribing from a podcast would remove it from your local playback history
- Fixed an issue that could cause the navigation bar to dissapear when opening and closing the player
- Fixes an issue where some items in Discover aren't tappable
- Fixes an issue where the link icon could remain on the player artwork even when there was no link
- Fixes an issue with the swipe actions being mis-aligned on rows that are 2 lines long

### 7.3 Build 605
- Added prompt when changing podcast episode grouping in Settings to apply it to all podcasts
- Added error message support to the episode card view
- Various small chapter progress design tweaks
- Fixed chapter name not being tappable in the previous build

### 7.3 Build 604
- Added new chapter progress UI
- Added Download All option for podcasts and filters
- Added support for 2 line episode titles, making it easier to tell in lists what an episode is about
- Tweaked Settings area to create general settings with various app settings in it
- Added ability to group podcasts by play status, download status or into seasons
- Fixed an issue with show notes unable to load message being displayed in the wrong theme
- Updated app to Swift 5, in theory this should mean smaller download sizes for App Store releases (not sure what happens in TestFlight)

### 7.3 Build 603
- Tapping add to Up Next in the episode card no longer asks about the position if there's nothing in Up Next
- Added an option to be able to single tap episode in Up Next to play them
- CarPlay will now show archived episodes if the app is configured to show archived episodes
- The app now remembers if you last had the chapter list expanded or not
- If show notes fail to load, there's now a retry button
- Added a message to the podcast page when all the episodes of a podcast have been archived
- Up Next list now shows whether episodes are downloaded/downloading
- Fixed an issue where a list title in Discover could squish the SHOW ALL button
- When you sign out, the app now takes you back to the Profile page
- Fixed an issue where the starred list would be a blank white page when nothing is starred on Dark Theme
- Performance enhancements to the various episodes lists in the app

### 7.2.3 Build 602
- Fix for database related crash

### 7.2.2 Build 601
- Fixed another issue that could cause your Up Next re-arrange to be cancelled
- Fixed a crash on the podcast page
- Fixed search results not being tappable on podcast page
- Performance improvements

### 7.2.2 Build 600
- When you search a podcast, the search box now scrolls to the top of the page to let you see the results more easily
- Fixed an issue where scrolling to the Up Next section could crash the app
- Fixed an issue where re-arranging your Up Next list could get interrupted by the app updating the page
- Fixed an issue with how our libraries were being linked into the project that might have caused some crashing
- Fixed the confirm Up Next clear dialog being unreadable when using the light theme

### 7.2.2 Build 599
- Removed some legacy syncing code that might have been causing issues
- Fixed a bug with how server settings are interpreted

### 7.2.1 Build 598
- Performance and stability improvements, including hopefully fixing one long running issue
- Updated no artwork artwork it's now the best no artwork artwork that has ever artworked

### 7.2.1 Build 597
- Fixed some playback issues and crashes introduced in the previous beta. Also some state issues with the lock screen or other devices not showing play/pause correctly
- Fixed an issue where sometimes you'd scroll through a list and see icons overlapping each other that weren't meant to be there
- Improved app start up time

### 7.2.1 Build 596:
- Fixed an issue where Pocket Casts could skip back up to 30 seconds during an interruption (navigation, Siri, etc)
- Minor Discover section tweak

### 7.2.1 Build 595:
- More playback issue fixes
- Added some dynamic parameters we can tweak server side

### 7.2 Build 594:
- Fixed a playback related crash
- Fixed the Now Playing screen on Apple Watch showing a disable button on the left, when you had our extra playback controls setting turned off

### 7.2 Build 593:
- Added some code to try and fix an ongoing playback pause/disconnect crash that's being reported
- Fixed a bug where you could the player could get into a state where dragging down doesn't close it
- Minor tweaks to the discover section

### 7.2 Build 592:
- Fixed an issue where if you change the episode limit on a podcast, the text in the list might not update
- Added first sign in handling for when you have an Up Next list, but the server doesn't
- Fixed Notification -> App Badge list not accounting for the mini player
- Improved padding/layout on the podcast page
- Added a setting for what the default Up Next swipe action should be if you keep swiping (eg: play next or play last)

### 7.2 Build 591:
- Added per podcast episode limits. Would be great to get your feedback on this for those that need it!
- Improved syncing of episodes you get to the end of
- Improved syncing of episode duration
- New archive/unarchive icons

### 7.1.1 Build 590:
- Added an option for CarPlay/Lock Screen Actions (Settings -> Playback -> Extra Playback Actions) [off by default]

### 7.1.1 Build 589:
- Added subscribe button animation
- Fixed some formatting/layout issues on the podcast page
- Added mark as played and starred actions to CarPlay

### 7.1.1 Build 588:
- Improved speed of viewing and unsubscribing from podcasts that have lots of episodes
- Fixed an issue where the full screen player would open and briefly show the mini player at the bottom
- Improved podcast artwork handling. It should still refresh itself in a timely manner, but not show you no artwork when it's doing it
- Fixed an iPhone SE issue on the profile page where your stats time labels could overlap
- Fixed an issue where you could star an episode, then go to Profile -> Starred and it wouldn't be there
- Fixed some pages being allowed to rotate into landscape on iPhone that weren't meant to

### 7.1.1 Build 587:
- Fixed mini player Up Next number going over the background when you got past 100 episodes
- Added swipe to close for video player
- Fixed an issue with stats start times not being sent to the server properly
- Fixed an issue where the app badge would also count episodes you weren't subscribed to
- 'Keep Screen Awake' setting in Settings -> Playback should now work correctly
- Improved app accessibility
- Fixed an issue where episodes could be marked as in progress when they actually aren't
- Archived episodes now appear 'grayed out'
- When playing a video rotating to landscape now auto loads the full screen video player

### 7.1.1 Build 586:
- Fixed an issue where playback history wasn't cleared correctly
- Fixed a player crash
- Listening history now shows 1000 episodes instead of 500
- Fixed divider colors on the Network page
- Fixed an issue where the podcast description could close while you were reading it

### 7.1 Build 585:
- Standardised 'Mark Played' terminology in dialogs
- Removed legacy archive text on the podcast settings page
- Fixed a minor bug with clearing playback history

### 7.1 Build 584:
New Features:
- When you long press on the skip button you can now choose to mark as played or just skip to the next episode

Improvements and Fixes:
- Option dialogs in the player are now dark, like the player
- Upped our episode limit so that you can see the full back catalog in shows like The Joe Rogan Experience
- Fixed a Chromecast issue that could cause your progress to get reset to 0 when you stop casting
- Fixed an issue where the app could remove podcasts you were browsing in the discover section
- Fixed the status bar color on the per podcast archive page being set wrong
- Fixed the status bar color on the podcast settings page being set wrong
- Fixed the mini player covering the "Clean Up" button on the Downloads page, on an iPhone SE sized device
- Fixed an issue that could cause streaming videos to fail
- Fixed the lack of contrast on option dialogs on the Extra Dark theme (being black on black)

### 7.1 Build 583:
New Features:
- Added a refresh button to the profile page, as well as displaying when your last refresh was

Improvements and Fixes:
- Fixed a bug that could cause episodes to be auto-archived when they weren't meant to be
- Changed "Now Playing" to "Playing" in the Apple Watch app so it doesn't take 3 seconds for the time to appear
- Fixed Volume Boost being named "Boost Volume" on the podcast settings page
- Added missing 38mm Apple Watch complication icons
- Adjust the episode page on Apple Watch for various watch sizes

### 7.1 Build 582:
New Features:
- Added long press play all and archive all options to the Downloads page
- Added unsubscribe button to the podcast settings page
- Added a long press option to the skip forward button in the player, let's you mark as played and move on

Improvements and Fixes:
- Fixed some player and download related crashes
- Up Next auto add limit is now 100 (was partly 50, partly 100 now it's the same everywhere)
- Fixed a crash introduced in the 581 to do with tapping on the Up Next icon crashing the app
- The list version of the podcast grid is now accessibility enabled
- Fixed: turning on notifications for a podcast in settings wouldn't refresh the bell icon properly
- Fixed the profile page header on the iPad running over the content
- Fixed an Up Next syncing issue that could cause duplicate episodes
- Fixed a first sign in issue that could cause your filters to be in the wrong order
- Fixed an issue that could cause the Inactive sync option not to work properly

### 7.1 Build 581:
- Added per podcast auto-archive settings that replace the previous opt-out of global auto archiving function
- Added progress indicator to Apple Watch Now Playing, tap the title to toggle it on
- Added support for the new watchOS 5 complication styles
- Updated the Profile tab so that the header scrolls with the rest of the table
- Fixed iPad issues with video playback
- Chapter links now open inside the app like other links
- Improved the delete filter animation
- Fixed an issue where you couldn't sort Up Next items above/below the height of your screen
- Improved performance of the Up Next list in the player when you have hundreds of items
- Fixed an issue where the app was a bit too agressive about cleaning up episodes that don't exist anymore
- Fixed an issue where your start from time for a podcast wasn't synced properly on first login
- Minor tweak to paging indicators on the Discover page
- Scrolling performance improvements
- Standardise search de-bounce times throughout the app
- Updated downloaded indicator icon
- Up Next auto add limit is now 100 (was 50)
- Added the date/season info to Up Next items in the player
- Fixed a bug with the color of the Add Filter button
- You can now tap the artwork in the player to view info for that episode
- Fixed a history syncing crash
- Fixed a date formatting crash
- Tweaked the spacing and design of the podcast page

### 7.0.2 Build 580:
- Fixed an issue where the edges of podcast artwork had artifacts
- Updated sync logic to fix a few more errors
- Replaced mark as played with archive in the episode notification actions
- Fixed an issue where your podcast page could be out of date
- Fixed an issue where your Tab Bar (and mini player) could disappear entirely
- Fixed an issue where if you turn on volume boost for a video the setting wouldn't get saved

### 7.0.2 Build 579:
- Fixed issues with colour matching on the network discover page
- Fixed an issue where if you had an overlay up in the player it would stay there after the episode had finished playing
- Fixed an issue with Episode Filter re-ordering
- Fixed an issue where episode synced to your Up Next list wouldn't be downloaded, even though you had that setting on
- Fixed the discover top featured section sometimes getting truncated to 1 line
- Fixed a threading related crash in the player
- Fixed the share podcast list page being under the navigation bar
- Fixed an issue where the settings cog could disappear from the profile page

### 7.0.2 Build 578:
- Fixed play all including archive episodes
- Changed Unplayed podcast grid badge to be Unfinished instead (thanks for the feedback on this)
- Fixed network page artwork being under the navigation bar
- Added 'Archive All Played' to podcast page as a quick way to archive all your played episodes
- Added an 'Unarchive All' option to the podcast page that appears when all your episodes are archived
- Various fixes for Siri Shortcuts
- Fixed an issue in Discover where you navigation bar could dissapear
- Fixed Up Next position field not appearing on the podcast settings page
- Fixed an issue where the background for various player overlays could be the wrong size
- Fix sharing episodes from the iPad player crashing the app
- Added an indicator to episode rows to show if an episode is in your Up Next list
- Tweaked some padding/spacing on the podcast page and episode rows
- Fixed some text colours
- Fixed a player related crash

### 7.0.1 Build 577:
- Fixed a CarPlay crash related to playing an episode that was already playing
- Fixed an issue with the filter edit options being under the menu button (introduced in a previous 7.0.1 beta)
- We no longer show archived episodes in CarPlay
- Player now shows chapter info as you scrub the timeline
- Tapping on the currently playing chapter when the chapter list is collapsed now expands that list and scrolls to the chapter

### 7.0.1 Build 576:
- Fixed various crashes
- Fixed an issue with Discover being blank in some regions
- Finished new search implementation for Discover and podcasts
- Reworked filter re-arranging and deleting to fix various issues
- Fixed issues with going from video -> audio with the video player open
- Fixed issues with going from video -> video with the video player open
- Removed delete option for chapters
- Fixed an issue with the app badge counting archived episodes
- Added handling for when a podcast doesn't load in the discover section
- Finished off Discover -> Load podcast animation
- Fixed issues with podcast settings and the episode card on the iPhone SE

### 7.0.1 Build 575:
- Fixed sign in pages being under the nav bar (introduced in 574)
- Fixed filter chips not working (introduced in 574)
- Ooopsy doopsy. Good thing we test internally first, aye ;)

### 7.0.1 Build 574:
- Updated the way discover and podcast search work so they scroll away when you scroll up
- Tweaked discover page spacing
- Tweaked podcast page spacing
- Fixed an issue where your sync data would get so large the app would stop syncing it
- Made the discover -> new podcast transition a bit nicer
- Set disk space limit on podcast images
- Fixed an issue where pressing play would toggle rapidly between play and pause
- Made the more/menu icon we use throughout the app consistently the same one
- Fixed wording/color/text on some of our warning/options dialogs
- Scaled the sign in page better on various size devices/screens
- Fixed a filter crash that would happen when it received an icon colour/type it didn't know about

### 7.0 Build 573:
- Doubled the speed of initial sign in
- Syncing fixes based on extensive testing
- Fixed a few more places the mini player was hiding content
- Fixed a few typo's
- Fixed a syncing issue where your episodes would be imported with no duration
- Fixed some visual designey things, including replacing a linear animation with ease in, ease out. You're welcome designers
- Improved reliability of the app downloading show notes when downloading shows (for offline viewing)
- Profile image heading now keeps aspect ratio so it doesn't get stretched
- Fixed signing out leaving the sign out option there after you did
- Added a message for when your Up Next list is empty
- Fixed an issue where in certain cases when you play an episode with chapters the next episode will still show those chapters.
- Performance enhanced

### 7.0 Build 572:
- Fixes some CarPlay and lock screen issues
- Added haptics to play/pause
- Fixed episode rows flashing when they update
- Added nav bar overlay to things like show notes when you scroll them
- Dismiss episode dialog when you hit play (but not pause)
- More Siri Shortcuts stuff (see previous build notes)
- Fixed some more bugs in the discover section, including ones introduced in the previous build
- Added picture in picture support for iPad
- More iPad tweaks
- Fixed an issue where the podcast grid wouldn't update when you get new podcasts

### 7.0 Build 571:
** Internal Only Build **
- Auto download for podcasts now knows about archived episodes (bug fix)
- Episodes added to Up Next will be un-archived if they are archived
- Fixed search results layout for iPhone Xs Max
- Added Siri Shortcuts (not yet fully implemented or tested). These may or may not work, but feel free to try them!
- Hopefully fixed the Chromecast discovery issue we've had for a while now
- iPad tweaks to grid, featured section and episode cards (still a few iPad issues left though)
- Removed beta storage row from Storage settings, no longer needed

### 7.0 Build 570:
- Fixed places in the app where the mini player covered content
- Fixed issue with playing items in CarPlay
- Fixed artwork not changing after you went from a podcast with chapters to one without chapters
- Fixed podcast -> unsubscribe not syncing
- Fixed Up Next auto download using the wrong flag to check if it could use WiFi or not
- BONUS dot is no longer coloured. Huge change, I know.
- Fixed issues with selecting colours in a filter resetting the name for it
- Home indicator now hidden for videos
- First sign in now syncs your stats too so the numbers don't say 0
- Fixed indicator and switch colour in filter options
- Fixed email address and password fields on sign in page running off the screen and under icons

### 7.0 Build 569:
- App icons updated. If you notice what the change actually was, you get a gold star.
- Fixed podcast settings -> filter selection page not working on dark theme
- Implemented more robust first sync. Meaning when you sign into a brand new device it should now look like your sync data looks (including your archived things which wasn't in any other previous build).
- Updated to new Google Cast library, but their release notes mention nothing about any discovery fixes...
- Fixed a long standing beta issue where if you made changes to an episode list further down a page it would jump around while it was updating.
- Various font and style tweaks
- Fixed the filter chip open/close animation
- Made filter option close button more tappable
- Implemented Accessibility on almost all of our new screens so that they work with TalkBack.
- Fixed a bug where adding a podcast to a filter from podcast settings, wouldn't set the filter as needing to be synced, so the change would never make it to other devices.
- Fixed issues with opening share links to episodes
- Fixed an issue where tapping a pocket casts link inside someone's show notes would cause the app to lose it's tab bar. For now those links do nothing. As a workaround tapping the Safari button and then tapping the link should work.

### 7.0 Build 568:
- Crash fixes
- A few new icons added
- Fixed date handling in episode cells just having a day name (broken in the previous build)
- New feature: if you have filters that filter by podcasts, you can now select new podcasts to add to those from the podcast settings page
- Disabled cookies for downloads to prevent user tracking
- Improved podcast expand/collapse heading animation
- Fixed a few issues with saving filters
- Fixed progress on an iPhone Xs max not going to the end of an episode card
- Fixed some theme issues
- Various design tweaks

### 7.0 Build 567:
- Fixed sleep timer custom time above an hour just saying "1 hour"
- Updated filter design. You can now show/hide the filter chips and there are now more filter chips so they are more readable
- Fixed an issue where changing a filter name wouldn't actually save that change
- Fixed volume control getting cut off on the 40mm Apple Watch
- Episode filters now obey the WiFi setting from Settings -> Auto Download.
- Fixed some data use logic where auto downloaded things would sometimes ignore WiFi settings
- Fixed an issue with the date predictions on podcast pages
- Opening shared lists (like https://lists.pocketcasts.com/kids) now works with ### 7

### 7.0 Build 566:
** Internal Only Build **
- Changed the defaults for newly created filters
- Went back to the latest version of Google Cast since that doesn't seem to be the issue with discovery we were having
- Fixed a bug where when you tapped on a search result on the podcast page and came back the app thought you had no podcasts
- Starred episodes page under profile implemented (you have to be signed in to see this option)
- Split episode status, download status and media type into their own 3 filter chips making it easier to see what you're filter is set to and change it.
- UI Tweaks in various places

### 7.0 Build 565:
- Fixed OPML import, it should now work
- Implemented a no podcasts state for the podcast grid
- Implemented auto download for Episode Filters
- Reverted back one Google Cast version to fix discovery issues
- Fixed some dark theme issues in the Discover section
- Fixed podcast search theme issues with dark theme
- Implemented the 'Latest Episode' badge option for the podcast grid/list page
- Design tweaks for the podcast grid page when in list mode
- Fixed unplayed episode count being wrong on the podcast grid badge
- Fixed crashes introduced in previous build
- Watch OS changes:
  - Now playing screen now has a volume control on it (works with the crown too)
  - You can now change playback effects from the now playing screen
  - The Up Next view is also available from the now playing screen
  - App now requires watchOS 5 or above
- Fixed some refreshing issues on the podcast page
- Fixed an issue in the filter page where you'd select podcasts for inclusion and they'd then unselect themselves
- Fixed issues with podcasts not being properly excluded from auto archive when you asked them to be
- Fixed issues with scrolling in the discover area

### 7.0 Build 564:
- Finished design of filters and filter editing
- Fixed time saved in player not matching the stats page
- Added long press 'Archive all from here' to filter pages (already added to podcasts in a previous build)
- Removed drag and drop implentation. Feels easier to swipe out the left actions and also it can't work together with long press
- Removed experimental 3D touch implementation from the podcast page until we figure out exactly what we want to do with it
- Discover area design tweaks
- Added a small amount of haptics for things like subscribing to a podcast, or skipping back or forward just to see what it feels like
- Fixed a CarPlay issue where tapping anything past the first episode in the 'Up Next' section would cause the app to crash
- Changed the astronauts sneezing stat. Turns out it's highly unlikely they sneeze 99 times a day. They still sneeze more though, since dust particles don't settle in space like they do on earth. That's right kids, you just got SCIENCED!
- Other small tweaks and fixes. My fingers are tired, ok!

### 7.0 Build 563:
*** Internal Only build ****
- More changes to filter chips + filter editing. Not finalised yet
- Added syncing of archived status
- Added switch to show archived option on the podcast page
- Starred option now only shows for signed in users (actual page not implemented yet)

### 7.0 Build 562:
*** Internal Only build ****
- [Work in progress] new filter editing
- New podcast page design + long press row actions
- Download indicator is now green again
- Google Cast discovery fixes
- Moved season/episode info into the first label on an episode row
- Fixed profile illustration background on dark and light themes
- Added support for reading season and episode info from the refresh server
- You can now tap the chapter title to scroll to that chapter in the list
- Player design tweaks
- Added share option for the currently playing episode
- Fixed home indicator not going away properly on the now playing page
- Added code to save your current position as you're playing
- Play button on episode card is now tappable everywhere

### 7.0 Build 561:
- Added support for showing season and episode numbers for shows where the author tags them with that info (design not quite final)
- Various small design and icon tweaks
- Implemented per podcast playback effects. These are now available in the settings area for a podcast
- More fixes for that pesky mini player showing/hiding at the wrong times

### 7.0 Build 560:
- Added Google Cast button back into the player, podcast page and filter pages.
- Fix video player controls hiding while you are using them
- Added new setting to allow headphones/bluetooth/car stereos skip whole chapters (off by default, check your Playback Settings)
- Fixed issues with tapping Up Next button scrolling to Chapters instead of Up Next
- Hooked up the button in the top right of the player
- Added 'Go To Podcast' option to episodes in the player
- Fixed an issue where the last chapter title would remain in CarPlay/BT interfaces even after it had passed
- Fixed an issue where the mini player would stick around even after you've finished playing
- We no longer hyperlink times people put in show notes unless it's the episode you're currently playing
- Updated a few more dependencies to Swift 4.2

### 7.0 Build 559:
- Finished the video player
- Fixed episode share links not opening properly
- Converted to Swift 4.2, and built with Xcode 10 (yay?)

### 7.0 Build 558:
* Internal Only Release *
- First pass at at a video player
- Small chapter selection fix

### 7.0 Build 557:
* Internal Only Release *
- Design and functionality tweaks to discover section
- Fixed incorrect chapter implementation

### 7.0 Build 556:
* Internal Only Release *
- Updated Discover page
  - Design Tweaks including phone size support
  - Theme support
  - Paging for Networks
  - Various other fixes and tweaks
- Update Player
  - Pull down on overlay views to dismiss
  - Tap background on overlay views to dismiss
  - Design tweaks for various phone sizes
  - Up next section now fully implemented (swipe to remove, correct times for episodes, etc)
- Chapter titles now sent to external devices (BT, CarPlay, etc)
- Crash fixes
- Colour related fixes

### 7.0 Build 555:
* Internal Only Release *
- New Design for Player (mostly finished, but not polished)
- New Design for Discover section (mostly finished, but not polished)
- Various other tweaks

### 7.0 Build 553:
- Added Volume Boost support for streaming
- Added Volume Boost support for video
- Added Trim silence support for streaming
- No way in hell am I trimming silence from videos, don't ask
- Airplay 2 support no matter what you're playing and what effects you have on or off
- Wrote 600 lines of Objective-C to do the above, and then wept a bit. The app is now only 92.33% Swift. :(
- This version might have a few playback bugs
- Added new playback option: Default Row Action. We figure it's important for people to be able to download as their main thing if they want, so it's back
- Updated profile page
- Moved downloads to Profile page
- Added starred to Profile page. This will show you everything you've starred regardless of subscriptions. I say 'will' because tapping it does nothing right now
- Added buferring state to the mini player, so you can see when things are, well, buffering

### 7.0 Build 552:
- Fixed the edit email option not working in the support section
- Fixed another crash in an effort to get to 0. Probably futile. Trying anyway
- Added support for regional popular charts to discover

### 7.0 Build 551:
- Hopefully fixed one of the longest running Pocket Casts bugs in history (background crash when disconnecting audio source) THIRD TIMES A CHARM! COME ONE WE GOT THIS! ༼ つ ◕◕ ༽つ
- Added first cut of new categories back into discover section. Again, none of the discover section is final design, but it should work

### 7.0 Build 550:
- Removed 'Stream By Default' setting and trying to live in 2018. The app now streams by default. You can still download things by setting up Auto Download or tapping an episode and tapping the download button. You can configure Auto Download for your Up Next list, Podcast or even in filters (that last one isn't in there yet, but it will be). Please give this new feature a few days and then let us know how you feel about it, we realise it could be contraversial for some.
- Interim Discover section as we move to a new more dynamic design we can update frequently and better. For now it's missing categories and the design is not final but it should be usable
- Fixed an issue with Japanese title's and our TitleShortenator(TM)
- Hopefully fixed one of the longest running Pocket Casts bugs in history (background crash when disconnecting audio source)
- Fixed: Archived episodes are no longer considered when sorting your podcast grid by latest episode
- Fixed: Unarchiving an episode now counts towards it not being stale
- Changed the default for auto archiving to not touch starred episodes. Thanks for the feedback on this one, as far as defaults go and with previous expectations in mind this a better default

### 7.0 Build 549:
** This build will sign you out of syncing. You will need to manually sign back in **
- Trying to fix most common background crash

### 7.0 Build 548:
- App no longer auto archives episodes on upgrade
- Auto archive now handles old episodes properly
- Archive all now, archives all (previously had old logic for auto migration archiving)
- Added message when hiding/showing archived episodes
- Fixed some of the more bizarre animations

### 7.0 Build 547:
- Experimenting with a new concept: Archiving.
  - If there's episodes you don't want to see or are done with, you can archive them.
  - Archiving an episode won't change where you are up to in it, or mark it as played, so there's no confusion about if you have or haven't listened to something
  - Archived episodes always have their files deleted, so when you archive something you automatically get back the storage space it was taking up.
  - Episodes you finish playing will be automatically archived after being played. You can however change this in settings to be after 24 hours or even longer.
  - Auto Cleanup has been replaced with Auto Archive, and you can choose rules for that in settings. You can no longer set this per podcast (since it's now time based there's no need to) but you can opt a podcast out of auto archiving.
  - Archived episodes do not appear in your filters and do not count towards your badge numbers
  - As a once off migration step, episodes you currently have that are played, but not interacted with in other ways (like downloaded or starred) will be automatically archived for you

### 7.0 Build 545:
- Updated to Google Cast library that fixes discoverability issues (especially when using device groups)

### 7.0 Build 544:
- Fixed About page crash introduced in previous build
- Fixed an issue where playback could be paused via Siri (or similar) but not be resumable

### 7.0 Build 541, 542, 543:
- Removed Shifty Jelly from about page, replace with Pocket Casts
- Updated urls used inside app to access various services
- Updated app dependencies
- Fixed some threading/concurrency issues
- Fixed chapter images being missing (broken a few betas ago)
- Fixed deadlock issue introduced in Build 542
- Fixed some memory leaks. Thanks Quentin for the Debug Memory Guide reminder!
- Fixed a background refresh issue
- Tweaked some cell colors for the dark theme
- Updated the dark theme to be more Mojave like

### 7.0 Build 540:
- Fixed being able to swipe sideways on the full screen player and ending up with no tab bar.
- Fixed podcast short links not opening properly in the app
- The app now updates download/stream URLs automatically so if the author changes them so do we
- Updated a whole lot of dependencies. Exciting. I know.

### 7.0 Build 539:
- Name under the icon is now 'Pocket Casts' since this seems to fit in iOS 11.
- Fixed the logo on the splash screen getting squished when tethering/phone call bar is up
- Attempting to fix some CarPlay issues I've had

### 7.0 Build 538:
- Skip buttons on the mini player now have proper hit targets (I can't believe none of you were willing to shave your fingertips)
- Small tweaks to mini player and list icon spacing and rounding
- Sharing urls are now HTTPS so they should be all fancy on Twitter
- Updated to Google Cast 4.2 to try and fix device discovery issues
- Added code to pull chapter url links from show notes (no UI for it yet though)

### 7.0 Build 537:
- Notification icon was missing a tick. It found it!
- Fixed some of the predicted next episode logic, old podcasts will no longer say there's a new episode any day now
- Improved the way the discover section loads
- Changed lots of code, will it be more or less stable: ¯\_(ツ)_/¯
- Podcasts in the network area now can be viewed and subscribed to (not sure when I broke that)
- Pop up dialogs: rounded corners, altered background, upper case titles, removed bottom line
- Updated splash screen design
- Other small design tweaks

### 7.0 Build 536:
- Fixed the app not refreshing properly when the podcast grid style is changed
- Hooked podcast list sharing feature back up
- Added an extra drop target so you can choose to play next or play last when drag and dropping episodes from a list into Up Next
- Made episode cards easier to dismiss (especially one handed)
- Skip forward and back times now sync with the beta web app

### 7.0 Build 535:
- Podcast grid no longer flashes when it's updating
- Fixed force touch shortcuts not working
- Syncing efficiency and speed improvements
- Fixed Navigation Bar heights being wrong on non iPhone X phones.
- Update to Swift 4.1
- Sped up syncing both for first sign in and in general

### 7.0 Build 534:
- Pocket Casts now attempts to clean up episodes that don't exist anymore, and you haven't interacted with. May Zeus have mercy on our souls if that goes rogue.
- Fixed the 15 minute sleep timer being labelled as 5 minutes.
- Fairly big code cleanup that's sure to introduce a few small bugs
- Fixed Mini Player having its own personal war with the status bar
- Fixed the download indicator wandering off the screen...maybe
- Download progress circle doesn't jump back/forward when a download finishes anymore
- Added background for download progress circle
- Account for Up Next numbers bigger than 9 in the indicator on the mini player
- Fixed: Open player in portrait, rotate to landscape, close player. Tab bar is half way up the page

### 7.0 Build 532:
- Unsubscribing from a podcast now deletes all downloaded files for that podcast. Don't worry the app will warn you before it does it
- Fixed badge setting always saying 'off' regardless of the setting you chose on the grid page
- Fixed crash on Downloads Page
- Fixed episodes on Downloads page going slightly under the mini player
- Slightly improved podcast header expand/collapse animation
- In theory if a podcast you subscribe to adds older episodes, or changes episode details the app will now pick those up. In practice this will probably introduce all sorts of fun new bugs!
- Fixed an issue where you could tap on a podcast in discover and not subscribe, then weeks later go back and the podcast wouldn't be up to date
- Trying out adding haptic feedback to skip & play functions on Apple watch.

### 7.0 Build 531:
- Podcasts will now have their titles, descriptions, links, etc updated if they have changed. For now this runs every time you open a podcast page, but we'll make that more efficient later
- Podcasts that didn't previously have estimated release schedules and times because you had them before we had that feature, now will
- Replaced more legacy code with new shiny code that's probably full of bugs
- Standardised row heights in the settings area
- Tweaked the way we do episode list headings to make them stick, but also to only use them for significant date changes, eg: you should see way less of them
- Tweaked a few colours here and there
- Tapping on a podcast name on an episode card opens that podcast
- Updated to Google Cast ### 4.1.0 to fix crashing and other bugs

### 7.0 Build 530:
- Fixed refresh issue
- Added fancy error and question thingies
- Started working on podcast search

### 7.0 Build 529:
- Fixed list sharing feature
- Fixed Apple Watch app not being in sync with the phone when you re-open it
- Tapping anywhere in the top part of the podcast page now expands that section
- Started work on making options/picker dialogs more friendly and intuitive
- Added ...More to podcast description so you can read the whole thing

### 7.0 Build 528:
- Fixed subscribe button sometimes being solid white
- Fixed up next count sometimes being solid white
- Fixed loading indicator on Episode card not working properly
- Fixed podcast loading indicator sometimes being the wrong colour
- New settings icons added
- Fixed: Navigation Bar buttons dissapearing when you start on dark theme and switch to light
- Cleaned up some stuff while Chris cracked the Design Whip (TM) behind me
- Fixed a formatting issue when an episode was exactly 1 hour long
- Fixed: you can no longer drag or delete the top part of the episode page
- Fixed an issue where the drop target thingy would stay up when you're not dragging anything

### 7.0 Build 527:
- Fixed an issue where in the dark theme you could get a fully white icon for play/pause
- Mark as played on episode card now animates
- Played episodes now show their progress as all the way along on the episode card
- Fixed a long standing bug with swiping gesture on pages that don't have a back swipe gesture causing other weirdness
- App now launches to the last tab you had selected
- Fixed theme changed while episode card up weirdness

### 7.0 Build 526:
- Implemented Up Next drag and drop properly. If you're on iOS 11+ you should be able to grab one or more episodes in a list and put them in your Up Next.
- Trying out a more slide up pull down model for the Episode page.
- Improved colours being chosen for the Podcast page.
- When you sign out you are now properly signed out (thanks Simon!)
- Improved syncing between old versions of Pocket Casts and this one

Things you missed from internal builds:
525:
- Searching for an episode on the podcast page now mostly works
- Added year for episodes that aren't in the current year
- Unsubscribing from a podcast now turns off auto download and push notifications for that podcast
- Removed legacy delete code and replaced with subscribe code. _grits teeth_ hopefully everything still works

524:
- Profile page now updates properly when you sign out
- Added episode progress gradient in (just for you Chris)
- Fixed mis-aligned nav view titles on some pages
- Fixed: if you have Auto Download Up Next turned on, the app no longer tries to queue up already downloaded episodes
- Hooked up sort order for podcast episodes
- Added UI for searching podcast episodes, but it doesn't do anything yet
- Added filtering button to podcast episodes, but it's not yet implemented

Known issues:
- Podcast page is missing sorting, search, bulk actions and filtering
- Occasionally the icon for the download tab bar might dissapear entirely.
- Bulk action for filters aren't currently in any menus (download all, etc).
- The previous long press actions from lists are missing (for the download/play button), this isn't a design change, we just haven't added them back in yet.
- Rotation has issues and is not really supported, especially when the full screen player is open

### 7.0 Build 525:
- Searching for an episode on the podcast page now mostly works
- Added year for episodes that aren't in the current year
- Unsubscribing from a podcast now turns off auto download and push notifications for that podcast
- Removed legacy delete code and replaced with subscribe code. _grits teeth_ hopefully everything still works

### 7.0 Build 524:
- Profile page now updates properly when you sign out
- Added episode progress gradient in (just for you Chris)
- Fixed mis-aligned nav view titles on some pages
- Fixed: if you have Auto Download Up Next turned on, the app no longer tries to queue up already downloaded episodes
- Hooked up sort order for podcast episodes
- Added UI for searching podcast episodes, but it doesn't do anything yet
- Added filtering button to podcast episodes, but it's not yet implemented

### 7.0 Build 523:
- Syncing related crash fix, sorry about that.

### 7.0 Build 522:
- Fixed filter list page not having theme support
- Implemented filter sorting and deleting
- Implemented create new filter
- Added swipe actions to Listening History page to match the rest of the app
- Podcast page should now refresh properly if you perform various actions like using the row swipe actions
- Up Next auto download default changed to off
- Hooked up share button on podcast page
- Hooked up share button on episode page
- Added long press -> Refresh Artwork to podcast page
- Added star/unstar to Episode Page
- Added progress to Episode Page
- Implemented add/remove to Up Next on Episode Page
- Fixed: Profile -> Seconds Listened, Seconds Saved don't yet update from your account info
- Swapped Cancel/Done and Sign In on Profile setup page
- Fixed: When you sign into the app, you're left on the sign in page with no indication it worked (just press back for now).

### 7.0 Build 521:
- Fixed light/dark theme handling on Episode page
- Added token expiry handling to Up Next syncing
- Fixed an issue where depending on how you sort your podcast grid unsubscribed podcasts would show there
- Added sign out option to profile page
- Links on the episode page are now tappable
- Fixed: sometimes when you download an episode on the podcast page, it would look like it got stuck at 9x%, even though it was actually downloaded
- Implemented download/delete fully on the Episode page
- Episode view tweaked to look more like the final product
- Added rounded corners to podcast page image
- App now remembers if your dark theme preference is for Extra Dark when using the long press to toggle themes on the Navigation Bar
- Show notes on Episode page now render properly when the theme is Extra Dark
- Changed filter navigation based on people's feedback (thanks everyone!)
- App now remembers the last filter you were on and loads that back up for you on relaunch
- If you change a filter name, that name is now reflected when you go back to the filter itself
- Filter edit page no longer cut off by the mini player
- Filter edit and add placeholders added, but not yet hooked up

### 6.9.2 Build 510:
- Fixed loading spinner being missing on episode card when loading show notes
- Fixed iOS 11 views bouncing around on UINavigationController transitions

### 6.9.2 Build 509:
- iPhone [redacted name] adjustments and tweaks
- Fixes Google Cast crash when casting to a group of devices
- Updated dependencies

### 6.9.2 Build 508:
- Watch app now has correct icon for Up Next

### 6.9.2 Build 507:
- Tweaked watch progress indicator corner radius and alignment
- Marking an episode as played on the watch now pops the episode card and refreshes the list you came from
- Added force touch options to watch Now Playing page to go to next (and previous) chapters. These only show up if the show has chapters.
- Fixed alignment/padding of Pocket Casts widget when the using different display text sizes

### 6.9.2 Build 506:
- Fixed issue with show notes getting cut off in the episode card
- Fixed alignment of now playing episode in Up Next list
- Added episode card to the watch. Force touch for some cool new actions on it
- Added playback progress indicator to the watch app
- Other small tweaks

### 6.9.2 Build 505:
- Fixed issue with filters that look at download status not returning any results
- Changed the default (for new installs) to not warn you when manually downloading over cellular

### 6.9.2 Build 502, 503, 504:
- Upgraded to Swift 4
- Replaced legacy UIWebViews with fancy new WKWebViews
- Cleaned up a lot of old code and replaced it with newer, shinier (and probably more buggy) code
- Enabled whole module optimisation. New Xcode, New Swift, why not right? (this will probably be reverted)
- Changed sharing to only share episode/podcast URLs without names or descriptions to work around a new iOS 11 bug
- Fixed change icon not working on iPad's with iOS 11
- Crash fixes
- Tweaked remove silence algorithm to make it slightly less agressive
- Changes in this build will cause all your images to disappear and be reloaded, this is perfectly normal :)

### 6.9.1 Build 501:
- iOS 11 CarPlay progress support
- iOS 11 CarPlay playback speed support

### 6.9.1 Build 500:
- Fixed show notes being loaded on the wrong thread
- Fixed: overriding audio output source (eg: tapping the audio routing icon and choosing a different route) causes the app to pause when playback effects are enabled
- Fixed some more cases where the play pause button would be showing the wrong status.
- Fixed mini player re-arrange not working in iOS 11 properly.
- Fixed an issue where the player would keep the show notes from the previous episode when it couldn't find ones for the next one
- Added one more icon. There will be no more icons after that, so please don't ask for them ;)

### 6.9.1 Build 499:
- Fixed tapping on an episode notification not taking you to that episode in the app
- Added alternate app icons

### 6.9.1 Build 498:
- Added option to auto download to add to the top of your Up Next list
- Show notes are now updated when the author updates them
- Performance improvements for people with lots of episodes (> 20,000)
- Fixed a bug where the end of tracks could get cut off when using remove silence
- Upgraded the way we do play/pause and skip animations. In theory this should fix all the bugs associated with these.
- Fixed almost all cases of the long standing bug where the status bar could change colours when an action sheet pops up from the bottom of the screen

### 6.9.1 Build 497:
- Added missing background to video player play/pause button
- Fixed mini player in Up Next mode, edit filter settings, come back half in up next mode half not
- Open player automatically is no longer defaulted to on, but the setting is still available

### 6.9.1 Build 496:
- Watch app now goes to the Now Playing screen if you tap an episode to play it
- App now auto opens the player when you tap play (trying this out because enough people asked for it, there's a setting in Settings -> Playback if you don't like it)

### 6.9.1 Build 495:
- Fixed an issue where you could play something on a Google Cast device, then disconnect and have your progress reset to where you first started

### 6.9.1 Build 494:
- fixed an where in some cases you'd try to seek to 0 while the player was paused and it wouldn't let you
- fixed orientation of the Dutch flag (oops, but you know we're from Australia, so everything is upside down!)

### 6.9 Build 493:
- Fixed a race condition that could occur if you where syncing while adding things to Up Next

### 6.9 Build 492:
- Sorting of podcasts on the grid page now ignores 'the' for sorting purposes
- Added Poland, Ireland and South Korea to discovery countries
- Fixed an issue where if you play a podcast to the end, then try to play it again it could immediately finish
- Fixed an issue where the number of extra episodes listed on the mini player up next list could be a weird number

### 6.8 Build 491:
- Added silence removal stat back in but made it clearer what it's showing and also changed the first run experience
- Removed default label text from the Watch App
- Added long press option to Play Next on episode download/play button

### 6.8 Build 490:
- Watch complication now tinted red on multi colour watch faces, also modular small icon is now smaller
- Launching watch app from watch complication now takes you back to the last screen you were on
- Fixed issues with now playing screen icon animations broken in previous build
- Fixed Up Next time remaining adding the now playing episode twice

### 6.8 Build 489:
Watch App Changes:
  - Fixed watch interface main screen flashing whenever you go to it
  - New Force Touch options on now playing page: Star/Unstar, Mark Played
  - New Force Touch option on Up Next: Remove All
  - Updated Now Playing screen to handle when nothing is playing
  - Episode filters now show a message when there's nothing in that list
  - added complication as a shortcut to the app, as per Apple's recommendations (and your suggestions): "Apps are not required to provide a complication; however, they are highly recommended, even if they just act as a launcher for the app."
Phone app:
  - Fixed starring an episode in a list not updating the episode in the player show notes page
  - Fixed clear all button on iPad crashing if you have more than 3 episodes in Up Next
  - Minor UI tweaks

### 6.8 Build 488:
- Fixed iOS app crash when you have an Apple Watch but not an Up Next list. This should solve the crash on launch issue people are having.

### 6.8 Build 487:
- Experimental Bluetooth bug fix: please let me know if you use Bluetooth and your play/pause doeesn't work or the time remaning/progress looks wonky
- Apple Watch app! Please note this isn't finished yet but it supports:
  - Now Playing screen to quickly see what's playing and control it
  - Up Next list to quickly switch to a different episode
  - All your filters and Downloaded lists to find something new to play
  - Think of it as a tiny little remote for the phone in your pocket
  - Known issues: missing UI polish, some screens flash when they update, some functionality not yet there, not much testing done to it yet. More interested in what you all think of the function rather than the form at this stage :)
- Other minor bug fixes

### 6.8 Build 486:
- Fixed a bug where if you had just one episode playing, and you hit play on a different one the app would start building an Up Next list
- Fixed a bug where the app would get confused about which episode is actually playing after moving from one to another and restarting the app
- Fixed a few other small issues

### 6.8 Build 485:
- Sorry for the double builds today, promise not to do that again!
- Updated to FMDB 2.7
- Fixed a bug where when getting to the end of one episode, the next one wouldn't play automatically.

### 6.8 Build 484:
- Implemented play all from here (it's been missing since Build 480, sorry)
- More Up Next fixes to do with switching episodes manually, or via marking as played

### 6.8 Build 483:
- Fixes some more issues with Up Next. Fingers crossed we are there now.
*IMPORTANT*: After installing this build please clear your Up Next list. You may still have issues if you don't

### 6.8 Build 482:
- Fixed an issue with going from one Up Next episode to another introduced in build 480

### 6.8 Build 481:
- Minor tweaks

### 6.8 Build 480:
- Converted quite a few really old classes from Objective-C to Swift, because reasons
- Episode file types are now updated when you download an episode, so say an author said "hey this is audio" and when we download it the server says "yo this is video" we now mark the file as video. We do this in a few other spots as well
- There's a lot of new code here, but I can't tell you what it's for, and the final bit of it is turned off until a later date. What a tease. I know.
- Quite a few low level changes and cleanup, it's like Spring cleaning, but for code

### 6.7.2 Build 479:
- Fixed mini player image not updating if you go from playing something with artwork to something with no artwork
- Switched away from tabs in CarPlay to see if that fixes connection issues, also upped the max items per list to 100 from 50.

### 6.7.2 Build 478:
- More CarPlay enhancements
  - attempted fix for connection issue
  - now playing episode is now in Up Next list
  - tapping now playing episode no longer pauses it
  - podcast list is now sorted the same way it is on your phone
- Added loading indicator to FAQ page
- Crash fix related to stats
- Added new stat unit (thanks Andrew!)
- Updated Google Cast version
- Sped up tap on mini player -> player open delay

### 6.7.1 Build 477:
- Battery life enhancements
- More CarPlay fixes to try and address the can't connect to Pocket Casts issue a few people are having
- Fixed issue with variable speed and some AAC podcasts

### 6.7.1 Build 475:
- Fixed some crashes reported in ### 6.7


### 6.7.1 Build 474:
- More CarPlay improvements
  - Don't show empty lists as per Apple's specifications
  - Update interface when an episode is marked as played in a filter or podcast page in the app

### 6.7 Build 473:
- CarPlay improvements

### 6.7 Build 472:
- CarPlay interface updates
  - Interface is now tab based to make navigation faster
  - Up Next list is now available
  - Fixed an issue with artwork sometimes showing or not showing on various pages where it was or wasn't meant to be
- Fixed share links not opening the podcast/episode they were meant to
- Push notifications now show a default image if one isn't available

### 6.7 Build 471b:
- Turned whole module optimsation back off...I'm going to guess this won't ever work properly
- Upgraded to latest libraries, including Google Cast 3.4.0

### 6.7 Build 471:
- Fixed Switzerland not working properly in the discover section
- Fixed issues with downloading episodes having the possibility to override data being saved by other parts of the app
- Fixed an issue with playback failing possibly marking a file as played
- Upgraded to Swift 3.1
- Turned whole module optimisation back on for this build, who knows it might actually work now?

### 6.7 Build 470:
- Streaming now starts much faster
- Replaced M_PI with Double.Pi to shut the compiler up (I wouldn't normally list these kinds of things here but one line change logs look weird)

### 6.7 Build 469:
- Chapter titles no longer cause the player layout to go up/down. Chapter buttons now disable on the first/last chapter.
- Fixed a bug where sometimes the Chromecast and AirPlay buttons would be mis-aligned.

### 6.6 Build 468:
- Fingers crossed fixed the episode sitting at 0:00 remaining and not realising it's finished

### 6.6 Build 467:
- Notification tweaks
- Fixed an issue where if you seek in the last few minutes of a podcast the podcast might decide it's finished

### 6.6 Build 466:
- Remove silly social links from show notes
- Nicer push notification formatting (including force touch/view)

### 6.5 Build 464:
- Refreshing podcast artwork now refreshes color information as well
- Fixed an issue introduced in the last beta where podcasts could end early, or not end at all (THE HORROR!)

### 6.5 Build 463:
- Sped up playback on iOS 10.3 when you go to resume a file you've already played.
- When Chromecasting the app no longer disconnects when you get to the end of the episode if there are things in your Up Next list (and if you have the app open it will go to the next one)
- Fixed an issue where you disconnect from chromecast, the app pauses, but still shows a play button
- Upped max intro skip time to 40 minutes (don't ask)
- Fixed: Noticed if I drag the scrub knob in the full screen player to a position it seems to jump back to the previous position before jumping forward to the position I dragged it to

### 6.5 Build 462:
- Fixed an issue that would prevent the app from switching to playing the downloaded version of an episode you're currently streaming (for those crazy people that download things they are currently streaming. Which is a cool hack btw for people with no data caps: stream an episode you want to hear right away, then also download it, the app will switch for you)
- Mini player play/pause now animates as well
- Added 'Mark As Played' to the mini player long press options
- App now automatically tries to calculate the duration of downloaded episodes
- Added chapter support for streaming files
- Improved performance in various sections of the app
- Filed bug with Apple: iOS 10.3 takes 10x as long to determine how many frames in an MP3 file vs iOS 10.2 :(
- The app now attempts to download show notes when an episode is downloaded
- Fixed episode show notes spinner not appearing on the light theme
- Added animations for the skip buttons

### 6.5 Build 461:
- Added start time to stats page (only shows for signed in users)
- Playing with some animations for the full screen player play/pause and skip buttons (experimental work in progress)
- Fixed an issue where the player would report the wrong playback position (causing all sorts of skip issues)
- Fixed an issue where when you tap play for an in progress episode the progress bar/circle could flash to a different position before going to the right spot

### 6.5 Build 460:
- increased timeout on sync call
- moved some libraries inside the project to try and speed up startup time
- Fixed an issue where if you continuosly skipped back and forward a lot eventually playback would start to stutter
rusty

### 6.5 Build 459:
- Crash fixes, especially related to getting to the end of an episode

### 6.5 Build 458:
- Fixed an issue where if you try to subscribe to a podcast you just unsubscribed from and are signed into syncing, Pocket Casts would duplicate the podcast.

### 6.5 Build 457:
- Effects player now starts playing even faster. ZUPER DUPER SPEED ACTIVATED
- Fixed a bug where episode you marked as play would continually be sent back to be synced again (oops)

### 6.5 Build 456:
***WARNING, EXPERIMENTAL BUILD, THIS VERSION IS FOR THE BRAVE ONLY***
- Fixed widget icons repeating, again, but I think I really fixed it this time.
- Battery life improvements for Effects playback (player used when volume boost or trim silence is active)
- General battery life improvements
- Fixed an issue where we might miss a tiny bit of playback progress when you switch episodes
- Experimental: playing with de-activating our audio session when audio is paused, to see if it fixes some issues (this may be bad)
- Toggle push on and off is now faster if you have lots of podcasts
- Fixed: if you have push on for all your podcasts and you add a new one, push is set to on for that one too
- Fixed an issue that prevented Toggle All from appearing on the iPad notifications page
- Fixed: opening an episode card didn't show download progress until the download got some more data

### 6.5 Build 455:
- Fixed widget icons repeating
- Fixed widget being empty until you make changes to your Up Next list in the app
- Dropped the opacity on the empty space cells on the widget
- Tapping on the currently playing episode in the widget no longer pauses playback if it's playing
- Fixed a bug where the app would pause/play (or 'glitch' in beta testing speak :) when you enter and exit the iMessage picture browser
- Implemented the player side of the player speed improvements. The EffectsPlayer (the one we use for Trim Silence and Volume Boost) now starts playback much faster than it did before. This means that hitting play inside the app should now be faster (whether you're playing something new, or just unpausing content). Please note that this doesn't address hitting play from Control Centre when the app has been killed. This is because the app itself has to be launched before it can process the play event. On an iPhone 5S the app takes approximately 0.8 seconds to launch. My next challenge will be to see if I can speed that up!
- Fixed issues with using Siri to pause then having the app resume when Siri closed
- Fixed episodes that had playback errors sometimes being marked as completed
- Fixed playback error icon not appearing for the currently playing episode unless you go out of the view and come back
- Downloaded Files cleanup page now remembers the last setting you used, also include starred is now off by default
- Fixed: Episode card - the shaded area changes as soon as a drag action begins. Seems to get darker?
- Implemented: networks - round corners on podcast artwork within networks
- Fixed an issue where the duration set on a playing episode could be wrong

### 6.5 Build 454:
- Minimum iOS version is now 10
- Added Widget, you can now access your Up Next list in style! (tap on one to change what's playing)
- Implemented new notification APIs from Apple
- Fixed deprecation warnings
- Added code to try and prevent duplicate Up Next episodes
- When you sign into syncing for the first time, we now try to load episodes you've starred that might be older than the 20 we load in by default

### 6.5 Build 452:
- Fixed the episode card coming up under the mini player on the podcast page
- Fixed podcast author text being too dark when searching the discover section in the dark theme
- Fixed play all from here option on the podcast page not working properly when you sort oldest -> newest
- Fixed issue where the time saved could read "_blank_ HOURS 59 MINS"

### 6.5 Build 451:
- Fixed discover bug with case sensitivity

### 6.4.1 Build 450:
- Fixed an issue where when you download a played show the played up to wasn't being set to sync correctly
- Fixed voice over text for podcast tiles in the grid
- Fixed grid resorting being slow
- Fixed options button going missing on the iPad podcast grid if you drill down into a podcast and come back
- Fixed Chromecast icon being the wrong colour on the iPad -> Podcast page

### 6.4.1 Build 449:
- Changed the way we handle show notes in the app (also fixes bugs with images in shows notes not keeping their aspect ratios)
- Added code to not auto search for feed URLs while you are typing them in
- Added Siri support for phrases like "rewind 2 minutes" and "skip forward 3 minutes"
- Fixed an issue where pressing play from Control Center could cause the app to play then pause
- You can now unsubscribe from podcasts you're actively playing without crashing the app. Damn you people are weird sometimes.
- Small-ish code cleanup

### 6.4.1 Build 448:
- Fixed: changing an episode while it's downloading results in the changes not being saved when the download is completed.
- Changed the way we get a users device token for push notifications

### 6.4 Build 446:
- Fixed: opening and closing the Global cleanup settings page would cause the setting selected in there to be saved against every podcast

### 6.4 Build 445:
- Fixed a bug where playback progress might not be correctly synced for the episode currently in the player
- Tweaked some other syncing code to make it more granular
- Changed the way we save some data about episodes to avoid race conditions where stale data could overwrite new data

### 6.4 Build 444:
- Fixed filter re-sorting not being permanent or getting synced

### 6.3.1 Build 442:
- Auto downloaded episodes that are past the cleanup threshold no longer get starred

### 6.3.1 Build 441:
- Fixed (in most cases) the flash you get on the podcast grid when you open the app to that page
- Enabled using the phones volume buttons to control Chromecast audio volume
- Updated to Google Cast SDK ### 3.3
- Fixed a crash bug
- Tweaked the way refresh and syncing work

### 6.3.1 Build 439:
- Fixed not being able to set some options in Podcast Settings (broken in last build)

### 6.3.1 Build 438:
- Changed the way auto add to up next works: it's no longer tied to downloading anything, it's just when new episodes come out
- Fixed: In dark mode on iOS, opening & dismissing the action menu (•••) for an episode darkens the status bar permanently

### 6.3.1 Build 437:
- Fixed an issue where the app would remove the podcast name further into the episode title than just the start of it

### 6.3 Build 436:
- Artwork goes bouncy bouncy when you play/pause. Blatantly stole...I mean we're echoing what iOS 10 does now in various places

### 6.3 Build 435:
- Added handling for when an episode fails to play right from the start
- Added code to cache images we were missing for things like the lock screen
- Tweaked the way we look for times in show notes to handle more cases (aka stole Phils regex from Android)
- Fixed a bug where long date formats (like spanish) would run over the star icon in the episode card
- Standardised the way we display dates in the Show Notes and Episode cards

### 6.3 Build 434:
- Changed the way the storage -> System Cache setting looks for files we don't need anymore
- Fixed: When you restore from backup you can have episodes listed as being downloaded that you no longer have the files for

### 6.3 Build 433:
- Fixed an issue where podcasts which didn't have a chapter at the very beginning broke the way the skip chapter buttons work
- Added more debugging to try and figure out filters with missing episodes

### 6.3 Build 432:
- Added debug attachment to figure out an issue with empty filters
- Fixed sync sign out not working properly
- Cleaned up some of the syncing code to remove legacy fields
- Changed the way images are cached to improve how the pre-caching works
- Fixed an issue where the episode duration wasn't getting set correctly on playing episodes
- Fixed an issue where if you started a stream then locked your screen, the app could get killed off before it could play anything
- Fixed an issue where when you get to the end of an episode the app might not go to the next one in your up next list

### 6.3 Build 431:
- Fixed mini player crash on 32 bit devices
- Fixed crash caused by some episodes occasionally not having a parent podcast
- Fixed an issue where if you had auto cleanup turned on the app would star episodes you were downloading
- Fixed an issue where the app wasn't correctly detecting what was in your up next list. This might have caused all sorts of issues (duplication, episode not being removed, etc)
- Fixed an issue where the app would try to stream an Up Next episode it had already downloaded
- Pre-emptively cache podcast images when new podcasts are added via syncing (or initial sign into sync)

### 6.3 Build 430:
- Stream by default enabled: When you long press on an episode you no longer get a 'Stream' option, it's now 'Download' :)
- Fixed an issue where locking your screen could cause the app to stop playback

### 6.3 Build 428/429:
**** NOTE: THIS RELEASE HAS A HUGE AMOUNT OF CHANGES IN IT, IF YOU'RE SCARED OF BUGS IT MIGHT NOT BE FOR YOU ****
- Changed the way we do podcast image caching to improve performance, download speeds and download sizes
- Migrated to Swift 3 (Please Apple, don't do this to me again with Swift 4)
- Replaced entire data layer since it broke. This is a fairly big change, so we're going to need to beta test it a bit ;)
- Fixed: Enable push for just 1 podcast (without ever having done it before), all of the podcasts are now enabled
- Fixed how we handle playback failures in the EffectsPlayer (thanks for documenting this beta testers!)
- Added a playback state failed to an episode, so now if it fails you'll see it in the episode row and can tap for details

TODO TEST:
- test if the fix to turn off push for all the other podcasts when you turn it on for just 1 on first install still works
- test having 2 episodes with identical published dates for sorting

### 6.2.1 Build 427:
- Fixed an issue where some podcasts would restart from the beginning instead of where you were up to
- Fixed edges of the artwork used in the share list animation being jagged
- Improved handling of Chromecast connects and disconnects. Fixes some bugs and the app will now auto play as well if you connect and have the episode paused

### 6.2.1 Build 426:
- Tweaked iPad selected state colours
- Added double tap on iPad nav bar header to quick change themes

### 6.2.1 Build 425:
- Fixed Google Cast related crash
- Fixed seek related crash
- Fixed server call related crash
- Fixed playback related crash

### 6.2 Build 424:
- Added support for CarPlay streaming vs downloaded indicator (requires iOS 10 or above to see)
- When you long press on a streaming episode you no longer get 'Stream' as an option, it's now 'Download'
- Fixed performance issues with scrolling in episode filters
- Various other performance improvements

### 6.2 Build 423:
- Feedback changed to in app email
- Fixed crash with canceling an internal timer
- Fixes an issue where you hit play in control centre (when it's all blank looking) and the app plays them immediately pauses
- Minimum iOS version is now 9.1
- Added support for scrubbing a podcast straight from Control Centre
- Added support for 3D-Touching links in the show notes page and episode cards
- Various tweaks to the share podcast list page
- Changed the sharing list animation. As glorious as it was to see your podcasts flying off the screen a certain designer told me that it *might* be a wee bit overkill. Designers. Pffffffffft :P

### 6.2 Build 422:
- Fixed an issue that could mean you don't get push notifications
- Crash fixes
- iOS 10.1 workarounds
- Sharing page changes

### 6.2 Build 421:
- Fix CarPlay related crash
- Pointed at new faster syncing server

### 6.2 Build 420:
- Come on iTunes Connect don't be difficult

### 6.2 Build 419:
*** AT THIS STAGE PLEASE DON'T SHARE THESE LINKS OUTSIDE OF THE BETA COMMUNITY ***
- Added a new podcast sharing feature where you can share a list of podcasts.
*** NO REALLY, PLEASE DON'T ***
- This version is built in Xcode 8 and we've switched a whole bunch of libraries, so it's coming in a bit hot
- Fixed a bug where the sleep timer would end at the end of an episode, instead of counting on in the next one
- Fixed an issue where the podcast artwork and colour would disappear when you hit subscribe
- Fixed: When you manually download an episode that's beyond the auto clean threshold, the episode is still removed when refreshing

### 6.2 Build 418:
- You can now change themes by double tapping the pocket casts logo on the home screen of the app
- Theme change in settings is now animated, because reasons

### 6.1.1 Build 416:
- Fixed: add an episode to up next from a podcast you're going to unsubscribe from, now unsubscribe. The mini player up next list doesn't update.
- Minor tweaks
- If the podcast authors server doesn't return artwork, the app will now try to grab it from our caching server instead. This isn't a magical fix for podcasts that have no artwork, but it's nice for all those author servers that don't do a great job of hosting files

### 6.1.1 Build 415:
- Added analytics to our notification actions to see which ones people use
- Fixed 'End of episode' sleep timer option not working correctly in some cases

### 6.1.1 Build 414:
- Chris is no longer your Auto Download Manager :(
- Fix for potential crash related to Chromecast

### 6.1 Build 413:
- Fixed: The time saved with remove silence seems to not handle 0 minutes and displays it as _blank_ mins
- Fixed: From the trending/top chart open a subscribed podcast, go to podcast, unsubscribe. When you come back it still has a tick
- Fixed: While in the discover section the trending/top chart summary doesn't update when you unsubscribe from a podcast
- Fixed: The Featured summary section now updates correctly when you unsubscribe from a podcast while in the discover section
- Fixed: Discover > tap the + icon to subscribe to a show, then immediately tap the row to bring up the podcast view > the button says 'Subscribe' instead of 'Go to podcast' > tap Subscribe > the button animates, but still says 'Subscribe'.
- More code hygiene stuff: cleaning up old classes that do the same as new classes. Also no more compiler warnings, bye bye deprecated methods!
- Fixed: Open Discover section with no Internet available, then connect to internet and do a search. The no internets message overlays the search result

### 6.1 Build 412:
- Fixed an issue with auto downloads where they wouldn't, you know, auto download
- Fixed: Pulling down on the iPad mini player while it's playing causes it to flash/disappear
- Fixed: Filter colour titles change instantly when you swipe back and have a few other issues if you use the swipe back gesture (this one feels good, it's actually been a bug for years, and was a hard to fix, but you know, I love you peeps)
- Chromecast now resumes correctly when the app comes back from the background, the previous builds of 6.1 would end your Google Cast session
- When you connect to a Chromecast device that's playing an episode from Pocket Casts and you're not currently playing anything, the app will now load what's playing onto your device.
- If an episode you're currently streaming downloads, the app will now automatically switch to playing the downloaded version
- Fixed: iPhone & iPad: queue up two video episodes and open the full screen player > when the second episode begins, the video will not be rendered in the player
- Fixed: share to iMessage from the show notes page in the player, when you come back everything is aligned funny
- Fixed some compiler warnings. Something something code hygiene.
- Fixed: typing Emoji into search no longer breaks search

### 6.1 Build 411:
- podcast images now fade in when they are loading on the grid view. You're welcome Chris.
- 'Refresh All Podcast Artwork' added to Settings -> Appearance
- Auto Download changed to download more than just the latest episode if the show appears to be a multi-part show
- If you cancel an auto download, or delete a file that is meant to be auto downloaded, the app will no longer attempt to re-download that episode
- Added auto download to main Settings page. Also designed the best damn custom icon ever.
- Added notifications explanation text
- Added Mobile network download option to the iPad version just like the iPhone one

### 6.1 Build 410:
- Added Downloads list to CarPlay
- Fixed podcast being left in CarPlay/Lock Screen/Control Center when you get to the end of it
- Added code to refresh the episode status of things in CarPlay as they change
- Fixed: When signed in and using the dark theme, the email address in the Pocket Casts Account page should not be black text
- Cleaned up divider lines on the sync signed in page
- Fixed: on the thinner iPhones a long variable speed saved time on the stats page runs over the label name
- Stats numbers are now formatted betterer eg 1039384 becomes 1,039,384 in AustralianaLand
- Fixed: if you set all your podcasts to "only keep last episode" when subscribing to a new podcast. It's set to "off". Should carry over

### 6.1 Build 409:
- Added support for CarPlay!
- Auto Cleanup changed:
  - Old Behaviour: delete downloaded file. Delete all information about episode.
  - New Behaviour: delete downloaded file. Mark episode as played.
  - Net effect: changes nothing in episode filters, means that 'cleaned up' episodes will appear on the Podcast page, but below any unplayed ones regardless of date. Fixes bugs & mis-understandings that can happen with things like the 'show more' button on the podcasts page and episodes you only just downloaded, etc

### 6.1 Build 408:
(note that this is the first build of 6.1, there's many more to come so this is a work in progress, expect some instability as we go)
- Added sorting to iPad version
- Added filtering to iPad version
- Added unread corners to iPad version
- Upgraded to Google Cast SDK ### 3, now allows for better reconnection and session management (not 100% tested yet, may be buggy)
- Skip buttons are now bouncy even when you're using Trim Silence/Volume Boost
- Improved app efficiency when running in the background

### 6.0.1 Build 407:
- When you tap the download button on a played episode, the progress is set to 0 now as well as being set to unplayed, just in case there's existing progress left in there somehow
- Pull to refresh now available in iPad filters. This is not our complete solution (that comes in 6.1) but it's nice to have a way to do it in the app somewhere in the meantime.
- iPad filter list now leaves enough room for the mini player
- Fixed a bug where if nothing is playing and you tap to play a video, closing that video would cause the mini player to also disappear
- Fixed podcast notifications appearing to be on by default but not actually being on
- Fixed enable Automatic Download in the Downloads settings > select Enable All > then disable Automatic Download. Subscribe to a new show > auto download is still enabled and the latest episode will begin downloading. (and also related issues to that)

### 6.0.1 Build 406:
- Trim silence time saved is now reported in minutes until it gets over 59 minutes (was previously 99)
- Fixed up next playlist not being selectable on iPad
- Mini player is now allowed in the discover section WELCOME OUR OFTEN MALIGNED LITTLE BUDDY
- Fixed various offsets in the iPad Discover section

### 6.0.1 Build 405:
Regressions fixed from previous beta builds (fixing bugs is hard, yo):
- Fixed an issue where using skip back and forward in Control Centre/Lock Screen/Apple Watch/etc could end up being multiples of your skip time
- Fixed an issue where if you didn't have enough podcasts to fill the first row they would get spaced out weirdly
- Fixed an issue where when you selected a podcast from the list view, it would stay selected when you come back
New fixes:
- iPad: fixed issues with the up next view and rotation (note that the arrow will still change colours on rotation, this is fixed in iOS 10 by Apple)
- iPad: fixed issues with podcast settings popup background colour (same note as above re: the arrow)
- Fixed: When episode is already playing, but the download is started, there is a funny back and forth between the pause button and the download progress bar (the download takes priority until it's finished now)
- Fixed the colour of the streaming pause icon being wrong
- Fixed an issue where the app wouldn't download some podcast images because of their funny URL characters
- Fixed an issue where the iPad grid view could go under the mini player cutting off the bottom row
- iPad text on is grid are now top aligned
- Fixed the 'Play all' function taking way too long to add things to up next and play
- Attempted fix for setting 3D Touch shortcuts related crash (not sure that was ever user visible, but good to fix all the same)
- Fix for playlist refresh related crash

### 6.0.1 Build 404:
- Fixed the iPad podcasts for notifications page running under the mini player
- Fixed: Opening stats in aeroplane mode results in an endless refresh animation.
- Fixed: incorrect keyboard type was selected for the sync sign in password field
- Fixed: iPad: If you're on the filter page while an episode is playing and pop up the episode card, it will auto close itself after a while
- Stop All Downloads on the downloads page now cancels both downloading and queued episodes. Previously it was only actively downloading ones
- Fixed: iPad podcast preview card showing white down the bottom in dark theme
- Fixed: Show notes in episode card now shows a scroll bar where appropriate
- Fixed: Show notes in full screen player scroll bar is now the correct color
- Fixed: iPhone 4S/5/5S devices no longer have a white line on the podcast grid
- Fixed: Rotating the iPad in such a way that it goes from the iPhone interface to the iPad interface (or the other way) no longer results in the app losing where you've navigated to
- Fix for crash reported via automated reporting
- Fixed: long pressing on the play/pause button in the mini player causes 2 end playback dialogs to appear

### 6.0.1 Build 403:
- Dates in Downloads area for things downloaded before version 6 are now handled better
- Added fix for lock screen/control center skip times sometimes being missing
- Fixed Dark Theme: tap on podcast that you already have -> tap go to podcast -> status bar is the wrong colour
- Fixed an issue where if you had your app badge turned off the app would accidentally clear your notifications as they come in
- Fixed the warning on the podcast -> download all option warning you about episodes it's not actually going to download

### 6.0.1 Build 402:
- Fixed a crash related to episodes that have no name
- Fixed retry button alignment on podcast page

### 6.0 Build 401:
- The 'Not Downloaded' filter option now includes episodes that are waiting for WiFi
- Show notes on the now playing screen are now always dark, to match the rest of the now playing screen
- Tweaked colours of episode row buttons
- Changed waiting for WiFi symbol
- Mini player artwork now has rounded edges, just for Chris
- For those with large libraries or slow phones the 'no podcasts' bit on the grid page no longer shows up before your podcasts load

### 6.0 Build 400:
- Auto search no longer fires when you type less than 2 characters
- If you type one character and hit search, the dialog that comes up is now dismissible
- Fixed: In the episode dialog if you tap download button and realise you have made a mistake and quickly tap cancel it doesn't seem to cancel
- Fixed: Sometimes tapping the download button on an episode card causes it to animate to downloading, then back to the button, then back to downloading
- Fixed: Search in discover, tap a result without pressing search, podcast card slides up under keyboard
- Fixed: when you are in a region we don't have in the discover area yet, the default is now World instead of US.
- Chapter artwork now only shows for the duration of the chapter it's applicable to, if chapters in between have no artwork they go back to the episode/podcast one
- Fixed some performance issues on the now playing page
- Improved the information in the support debugging email
- Bug fixes for application badge and keeping it up to date
- Fixed issues with the unread counts not being updated properly on the podcast grid/list view
- Fixed: iPad: With an episode loaded in the mini player > change the skip increments in settings > mini player will not update the skip increments until a new player is loaded/the app is relaunched
- Fixed: iPad: deleting the top filter doesn't select another one in the app correctly which leads to other issues
- Fixed issues with the podcast grid when shown in the smallest iPad split screen view
- Fixed: iPad: From an episode filter > tap an episode row > then tap the podcast title to jump to that show > the podcast screen will load tucked under the side menu
- Fixed issues with the iPad full screen player and rotation
- Fixed: add a new podcast from a share link with the tiles page open on iPad, podcast doesn't appear until you go back to the page
- Fixed issues with the episode card on the Downloads page on iPad
- Tweaked episode card background color on dark theme
- Fixed stream button & title on episode card being the wrong color
- Fixed episode filter related crash

### 6.0 Build 399:
- Fixed no podcasts page being broken in landscape on iPhone
- Fixed no episodes page being broken in landscape on shorter phones
- Added apostrophe to a page for our Vampire Count impersonating friend
- Cleaned up divider lines on iPad
- Fixed: Open Downloads, use cleanup to delete everything, when you return to downloads, all of the episodes are still displayed, though they’re no longer downloaded
- Fixed an issue where starting a lot of downloads at once would cause them all to compete with each other for resources and time out
- Made Clean Up button on Downloads page less scary looking
- Failed downloads from more than 2 weeks ago no longer show up on the Download page
- time units in the stats page have now been emoji-fied
- Fixed app badge not being set properly after a while (I think, maybe, we'll find out I guess)

### 6.0 Build 398:
- Fixed: if you pause a video from the mini player, it will open the full screen player
- Fixed: In landscape, tap into a network > there seems to be a space for the status bar at the top
- Fixed: Discover section: open a podcast from the podcast preview card, go back, the mini player shows up if you're playing something even though it shouldn't
- Fixed: video player controls fading out while you're skipping or scrubbing
- Fixed an issue on the iPad popup cards where you could end up with one half faded out on screen
- Fixed alignment of skip buttons on small iPhones
- Fixed podcast list view not updating when new artwork was downloaded
- Fixed iPad split screen bug where the artwork would flow over the edges of the page
- Fixed: When I have the playback settings panel open, and then the podcast changes, the settings don't update to reflect the new podcast (when settings aren't the same between casts - e.g. playback rate)
- Fixed: with an audio episode in the player, add a video podcast to upnext, tap it in upnext and swipe back to player. The episode is playing but you cant see the video
- Fixed: If in landscape mode with an audio podcast and the next podcast is a video podcast, no video is shown. Rotating to portrait looks funny and rotating back to landscape then shows the video
- Added no episode state for filters
- Added no podcasts state for iPad and iPhone
- Unlocked Achievement: All project assets are now in Asset Catalogues

### 6.0 Build 397:
- Accessibility:
  - Fixed Podcast Page
  - Fixed Sync Intro Page
  - Fixed Sync Sign In Page
  - Fixed Stats Page
  - Fixed About Page
  - Fixed Discover Page
  - Fixed Network Page
  - Fixed most of the Now Playing Page
  - Fixed Effects Page
  - Fixed paging control used in discover and now playing screen
  - Fixed all our custom round buttons
  - Fixed various other custom controls
  - Fixed Episode filter edit page
- Added Google Cast and menu button to iPad Downloads page
- Fixed: Up next buttons not updating properly on the Downloads page
- Hooked up tap on podcast title from Downloads page
- Added support for streaming playback failures
- Fixed: Video player landscape scrubbing
- Updated various libraries that the app relies on

### 6.0 Build 396:
- Certificate changes

### 6.0 Build 395:
- Fixed: Tapping download no longer dismisses the pop-up, but also doesn't show progress until pop-up is closed and reopened
- Cleaned up app startup logic and code
- Fixed: If you go to Discover (and this only occurs if the “Trending” and “Most Popular” tabs haven’t been loaded/cached yet), tap on “Most Popular” but tap back on “Trending” before “Most Popular” has loaded, then the tabs don’t do anything anymore after that.
- Cleaned up remaining constants left in prefix file, deleted prefix file (that ones just for my future sanity kids)
- Cleaned up the code that sets the app badge number
- Fixed: In the miniplayer upnext list, if you press and hold on an episode and don't remove it by just letting go, it will automatically start playing that podcast
- Fixed skip button animations on the full screen and iPad mini players
- Fixed wrong no artwork asset being used on dark theme in some places
- Changed mark as played swipe color for dark theme
- Fixed various issues in discover section
- Various other UI tweaks

### 6.0 Build 394:
- Fixed a bug where the downloads page would appear blank even if there were episodes available that should have been in there
- Fixed splash screen pocket casts icon not appearing on some phones
- Fixed an issue where where when playing at higher speeds than 1x, the app wasn't bufferring the equivalent extra amount required.
- Fixed: The +/tick icons in position 1 of Trending and Most Popular aren’t aligned with the rest of the list.
- Fixed: Open Discover > enable Aeroplane mode > open any Category > we should display the ‘No internet’ message here instead of an empty list
- Category lists no longer show a divider on empty rows
- Fixed: iPad: Editing an episode filter slides under the side nav
- Fixed: iPad: Add an episode filter > tap ‘All’ in the ‘Included Podcasts’ section, the left of the screen is blank, where the side menu is usually displayed.
- Fixed the episode card display on light and dark themes on the iPad
- Fixed: iPad: Settings > About > podcast tile background is not full width.
- Clean up button in download cleanup area is now inactive until there's actually something to delete

### 6.0 Build 393:
- New assets for mini player remove popup
- Fixed: On the iPad if you add more filters than the screen can fit you can’t quite scroll to the settings icon
- Changed our bluetooth/external device reporting to only set the playback speed to 0 or 1 depending on if we're playing or not to try and fix some BT bugs.
- Added arrows back in to podcast list view
- Made drag to reorder on podcast list page more fixed if you're in list view
- Fixed an issue where when re-ordering filters on the filter page if you let go on the 'Create Filter' option it would get stuck
- Episodes that are waiting for wifi now show in the Downloads area

### 6.0 Build 392:
- Added a fade in to image loading in various places
- Fixed: the placeholder image on the dark theme for images had white bits around it when it was loading
- Fixed the weird create episode filter behaviour on the iPad
- Fixed: deleting a filter on the iPad wouldn't cause the next filter to be selected properly
- The divider line on the iPad side navigation now updates correctly for theme changes
- Fixed: iPad: mis-alignment between top Podcasts item and the podcast content page
- Fixed: Remaining time on the now playing page can go into negative when Apple estimates the duration wrong, should fix it so it stops at 0:00
- Fixed: On the download assistant page you can swipe the mini player to the add to up next mode but the play buttons don’t change to plus buttons
- Fixed: list view on the main grid wasn't sortable
- Fixed: weird offset issues with toggling between the various grid/list views on the tiles/list page
- Added the no downloads state to the Downloads page

### 6.0 Build 391:
- Fixed an issue where auto download would download played episodes

### 6.0 Build 390:
- Added the ability for the app to queue up episodes for later download over WiFi.
- Related to the above fixed issues with downloading and various app state changes
- New podcast tiles corner asset + font change
- Fixed: Tap Refresh artwork, the art will commonly flash the tint colour twice
- Fixed: When the colour updates on the podcast page, the background changes but the list buttons don't
- Episode card now shows file size when the app is in Stream By Default mode
- Episode card shows just the date when the episode file size or duration are missing instead of "[dot] -"
- Fixed issue with the podcast settings popup and rotation/landscape
- Fixed: Tapping download on Episode card causes the card to dismiss
- Fixed: In episode filter settings, the Playing State, Status and Episode Type rows are tappable, which seems odd given the tap has no function
- It's no longer possible to create a filter without a name.
- Fixed: Start playing an episode so that a mini player is displayed. Tap any episode row to bring up the episode notes, tap a link in notes to open it in Safari. When you tap Done in Safari and return to the app, the mini player is now on top of the episode notes, obscuring the bottom of the notes
- Fixed: - With one episode playing/queued, swipe left on the mini player to enter Up Next mode, tap the mini player to open the full Up Next screen. Tap edit, mark the playing episode as played. Player will close, but the app is still in Up Next mode, with every episode displaying + in place of download/play.
- Fixed an issue where rotating the Episode card would cause the font to get bigger in some podcasts
- Fixed: First second or so of a podcast gets cut off. Regression in build 387 onwards?

### 6.0 Build 389:
- Discover section:
  - Cancel button only shows when you're searching
  - Added handling for when the page fails to load, and a nicer animation for the loading part
- Fixed the playback scrubber on the iPad mini player
- Fixed an issue that could cause the download progress to be displayed as 'nan%'
- Fixed an issue where playing a podcast with chapters, then marking it as played, then going to one without would still show the chapters in the player

### 6.0 Build 388:
- Fixed: in Settings -> Notifications the number of podcasts chosen field is not updating when you go back to it after selecting some
- Fixed: Dictation wasn't working properly with the search bar in the discover section
- The search bar in the discover section will now auto-search as you're typing
- Simplified the Remove Silence feature. It's now just an on/off switch
- Remove silence time reported on the Now Playing page now handles long times as well
- Reworked the Download Assistant to make it simpler and more useful. It's now just a place where all your downloading, downloaded and failed downloads go with easy access to auto download settings and cleanup.
- Added new mark as played asset when swiping away episodes

### 6.0 Build 387:
- Fixed: The region flags have a light theme drop shadow.
- Fixed: The default discover artwork is using the light theme image.
- Simplified data use setting (previously called 'Warn When Not On WiFi')
- Moved stream by default to be a Playback setting, instead of a storage one
- Fixed: In the discover section the author text is too dark on the dark theme.
- Fixed: The discover podcast artwork description has a coloured background but the rest of the popup doesn't when on the dark theme.
- Pointed discovery section and other parts of the app to our new static server cluster
- Fixed: On the add filter screen the options 'Playing state', 'Status' etc descriptions are quite faint on the dark theme.
- Fixed: The add filter included podcasts screen has a white background on dark theme.
- Fixed: In the discover section the select region list item has a border on the left but the other rows don't.
- Fixed: Connecting to a chrome cast device with no currently playing episode crashes the app
- Fixed: Video episode rows have a video icon with a white triangle in the middle on the dark theme
- Fixed an issue where the app wouldn't pause when headphones or bluetooth were disconnected
- Fixed an issue where the app would mess up after pausing for notifications a lot
- Fixed: Episode Filters that don't have enough episodes to fill the screen no longer show empty divider lines

### 6.0 Build 386:
- Fixed zombie iOS 10 downloads (eg: where downloads could sometimes never be resumed)
- Fixed an issue with moving downloads from the foreground to the background queue would fail and cause weird issues
- Fixed a bug where adding a new podcast when auto download is turned on could cause the new episode to be downloaded over your cell data

### 6.0 Build 385:
- Fixed a bug with the time saved for variable speed playback being recorded incorrectly
- Fixed: mini player covers content on the download settings page when it's up
- Fixed an issue that was causing crashing on the iPhone 4S when adding episode to Up Next
- Fixed: podcast settings not opening on iPad
- Fixed: all the instances where prompting you for confirmation would cause the iPad version to crash
- Other iPad tweaks (still a few more to come)

### 6.0 Build 384:
- New splash screen assets
- Update sync intro page assets
- Fixed: Long pressing on a chapter leaves it permanently selected
- Fixed: Going from a podcast with chapters can leave the chapters from the previous episode there

### 6.0 Build 383:
- Tentative MP3 chapter support. Tested with ATP and Upgrade (the episodes that had chapters anyway) let me know if you have any podcasts you know have MP3 chapters but this doesn't work with.
- Improved AAC chapter support
- Fixed issues with how chapters were being read and the way you skip through them.
- Performance/Power profiled the app and reduced memory and CPU usage, increased performance. Specifically during playback and downloading.

### 6.0 Build 382:
- Fixed: streaming over a poor connection could lock up the UI until the stream started.
- Related somewhat to the above, removed support for parsing chapters in streamed files

### 6.0 Build 381:
- Tweaked Podcast preview card to show episode date and how long ago it was published
- Fixed a restore bug where if you looked at a podcast, then went back to the grid, the app would keep trying to restore you back to that podcast
- Podcast images are now downloaded when you subscribe to a podcast, not later when you try and view them
- Removed grid image colouring thing in favour of using the actual podcast colours
- Cleaned up image caching code as well as grid caching. The main podcast grid should now scroll smooooooother
- Fixed: Downloads that ‘get stuck’can still look like they are downloading when you re-launch the app even when they aren’t
- Fixed alignment of Trending and Most Popular charts
- Trending and Most Popular charts now scroll much smoother
- Overhauled image caching in the discover section to make it faster and more reliable

### 6.0 Build 380:
- Fixed (server side actually, but whatevs) podcast colours
- Fixed: Just noticed if you tap and hold on the icon to change the grid layout in Podcasts, the app crashes
- Fixed the forgot password page on dark theme
- Various other small tweaks

### 6.0 Build 379: The post WWDC Lab Engineer assisted release!
- Fixed an issue where app wouldn't pause for spoken audio
- Fixed an audio playback scheduling issue that is too nerdy to explain
- Fixed issues with iPad status bar color on dark theme
- Added picture in picture button to portrait iPad video player
- Fixed tint color of share button on the show notes page
- Fixed stepper color for dark background
- Fixed iPad side navigation selected color and divider color
- Fixed iPad podcast grid title color being wrong on the dark theme

### 6.0 Build 378:
- Fixed: Dark Theme: network section has white at the bottom
- Fixed: Network pages are missing colours for now
- Various tweaks in the discover section
- Fixed: changing from the dark theme to the light doesn't update the title bar tint, so the white button and title disappear
- Fixed: top colour of podcast card when in dark theme

### 6.0 Build 377:
- don't autocorrect email field
- changed support section URL
- fixed issues where sizes were being padded to 3 places...man that's a hold over from like Pocket Casts 2.0
- added support for only searching in the iOS section of the knowledge base
- Discover podcast card now has rounded corners. Our long national nightmare is finally over!
- Dark theme colour tweaks
- Fixed: iPhone: rotating the podcast grid from landscape -> portrait causes the podcast artwork to go under the navigation bar
- Fixed: status bar no longer changes colors when an action sheet pops
- New Pocket Casts notification sound (may not work until we roll out the next server update)
- Added Easter Egg (it's tradition)

### 6.0 Build 376:
- Fixed the issue that caused build 375 to sign people out of our syncing service. Ironically this will probably sign you back out if you signed back in with build 375 (or actually if you had build 375 installed at all, sorry!)
- Fixed: iPhone: rotating the base page when the mini player is showing causes the page to offset weirdly
- Fixed: Sign in button looks odd when disabled on the dark theme
- Fixed: Subscribe button animates to the on state when you switch between Trending and Popular
- Changed podcast images to be Scale to Fill, people with rectangular artwork be damned
- Fixed: status bar colour of select podcasts for filter page
- Fixed: standardised touch states of table cells, added one to the base page
- Fixed: you shouldn't be able to drag the create new filter row around (also it crashes when you try)
- Fixed: iPad not restoring correctly to the podcast page
- Fixed: various dark theme selection issues
- Fixed: iPhone page restoration issues

### 6.0 Build 375:
- Fixed: I broke the bottom (main?) app page allowing enough room for the mini player
- Fixed: Filter podcast search bar, couldn't see the text on the dark theme
- Images for networks in our discover area are now cached properly, and no more weird flashing when the page loads
- Fixed: colour of the status bar on the network podcasts page
- Fixed: page dots not updating when you go to the end of the networks list in discover
- Fixed: iPad, full screen player tap share -> crash
- Fixed: iPad, episode card, tap share -> crash

### 6.0 Build 374:
- Fixed: when re-sorting filters: 1) Tap-and-hold a filter and move it to another position. 2) Tap-and-hold a different filter. 3) Crash
- Fixed: Open an episode filter in portrait, then rotate to landscape, the top offset is wrong. Same when you rotate back to portrait
- Now Playing, Show Notes, Up Next pages now have their proper titles when you swipe between them
- Dots on Now Playing page en-smallened
- Category icons removed
- Added selected state for featured and network cells in the discover section
- Fixed: Subscribe button jarringly appearing when the latest episode has been loaded on the podcast info page
- Added line below the trending and most popular tabs
- Fixed color of the top trending/popular item being the wrong way around
- Added subtle drop shadow to podcast artwork in the discover section to handle white artwork
- Various other discover section tweaks that are too fiddly to list
- Fixed a bug for syncing users where unsubscribe from a podcast, and then go to re-add it but can't
- Fixed: edit a filter with an episode release date setting of 'Anytime' would select last 24 hours when you tap into it
- Removed unused image assets
- Fixed: grey background behind the featured items collection view
- Added dividing line under discover search box

### 6.0 Build 373:
- Fixed: The saved time on the effects page is always in seconds, need to change units when the number gets bigger
- Fixed: With playback effects on, playing through the speaker then plugging in headphones causes the podcast to pause
- Fixed: Pressing skip in remove silence/volume boost mode can cause pops and stutters, need to smooth out the skip process
- Fixed: Time remaining on up next page now shows hours where required, and also updates when you remove items from Up Next via that page
- Fixed: when using remove silence/volume boost the app will now resume after phone calls

### 6.0 Build 372:
- Fixed an issue that could cause the same podcast to be added twice to your collection
- Fixed the no search results page for the dark theme
- Fixed network page dots being cut off after Monica selfishly added more networks
- Improved start playback speed, now when you hit play, it plays straight away, like all day, it rhymes, ok?
- Small UI tweaks
- Updated various libraries the app depends on
- Fixed: When you first install ### 6.0 we add three new filters: New Releases, In Progress and Starred. However we should check to see if you already have something that looks like In Progress or Starred, and if you do not create those two.

### 6.0 Build 371:
- Trying to fix mysterious notification crash. Made sure all add calls were balanced by remove ones. Programming is fun!
- Choose podcasts in Download Assistant items are now ordered alphabetically
- Cleaned up some underlying code, not really sure why that's a change log item
- Fixed: Podcast settings doesn't properly implement Dark Theme

### 6.0 Build 370:
- Fixed: App no longer crashes when launched from Control Centre after being killed off (eg: you can now hit play in CC or your headphones even if our app has been killed off. As long as it was the last thing playing it should get woken back up and continue)
- Gave the playback slider knob a bigger hit target for easy scrubbing
- Fixed a bug where the playback slider popup overlay would be blank on first tap
- Fixed issues with the discovery section and the ticks not updating when you subscribe/unsubscribe from a podcast
- Made the less/more knob for effects smaller (just for you Chris)

### 6.0 Build 369:
- Fixed: When you unsubscribe from a podcast, the message has the word Optional(“”) in it
- Fixed: Picture-in-picture button doesn't work properly unless you first hit play on the video.
- Fixed: iPad tap create filter, hitting cancel does nothing
- Fixed: iPad Podcast page missing top right options button
- Fixed: iPad: If you rotate from a 2/3rds Multitasking view in landscape, to the portrait version (or vica versa) you might end up on a different page
- Added new CMS backed support section (ignore it for now, it's a work in progress outside of the app itself)
- Added primitive support for display of playback bufferring. Currently only really works for initially hitting play
- Fixed: effects button doesn't change until you press play pause
- Fixed: Opening a filter list can cause it to shift down by 1 pixel after it's displayed
- Fixed: The pull to refresh control on the filter pages can occasionally cause the date headers to get stuck further down the page and obscure content
- Fixed: Chromecast support was broken in a previous build, it should work properly now
- Updated various libraries the app relies on

### 6.0 Build 368:
- Fixed: search in discover area now has dark search results and dark keyboard when using the dark theme. So dark.
- Fixed: support search now has dark keyboard when using dark theme
- Podcast page episodes now show video icon if it's a video episode
- Podcast page episodes now show star icon if the episode has been starred
- Removed the placeholder 'DOWNLOAD ERROR STUFF BROKES' which to be honest I'm going to miss
- iPhone: On a clean app open, the app now remembers which top level page you were on where appropriate
- Added icons for help & support (playback and troubleshooting)
- Fixed: Dragging the episode card up and down a bit can cause it to go transparent

### 6.0 Build 367:
- Fixed OPML share dialog so that other podcasting apps appear
- Implemented OPML import
- Added support page (note: placeholder images for two categories and currently we don't cache the FAQ answers)

### 6.0 Build 366:
- Implemented About page
- Implemented Export page

### 6.0 Build 364:
- Added proper text to sync intro page (thanks Monica!)
- Added 1Password integration for our sign in page
- Added forgot password to sign in page
- Fixed: If you have a sync account and you pull to refresh once, then again in less than 15 seconds, the pull to refresh animation will sit there forever
- Fixed: iPad: tapping download all button on a filter crashes the app
- Fixed: In landscape the search box is positioned wrong on the podcast list page
- Fixed: In landscape the search box is positioned wrong on the discover page

### 6.0 Build 363:
- New podcast collection icon for base menu
- New sign in/create account pages (don't freak out Chris, I didn't implement your fancy checklist yet)
- New signed in account page
- Fixed: the more/less remove silence slider doesn’t appear in landscape
- Fixed: Tapping ‘Trim Silence’ while the podcast is paused, causes it to play
- Fixed iPad navigation:
  - tapping on a page you're already on, takes you to the base page
  - pages no longer load under the side nav
  - search bar on the discover page is now at the top where it should be
- Dark Theme Fixed:
  - Episode card background before loading show notes is white
  - Full screen player show notes links aren’t using the right colour, can sometimes disappear
  - Podcast card (in discovery section) is still white

### 6.0 Build 362:
- The effects page now works in landscape on iPhones. The buttons no longer stretch crazy wide on iPad either. Dear Lord: May I never have to fight Auto Layout and Size Classes again. Amen.
- Tapping the sleep timer button on iPad no longer crashes the app
- Tapping a running sleep timer now gives you the option of adding a bit more time or cancelling it, rather than instantly cancelling it and leaving you wondering WTF just happened
- Turns out I fixed this in the last build by accident. So Imma take credit for it now: Fixed: open show notes and scroll to the bottom then open a link at the bottom then dismiss the webview the scroll position of the shownotes resets to the top
- Trying out a new compiler setting to see if the app crashes more or less with it on. A/B testing!
- Show notes are now dark in the dark theme
- Fixed: The '+' button on the podcasts page will sometimes disappear
- Table cells on the Stats page no longer have tap states. I know that was keeping some of you up at night, sorry!
- Fixed: I clipped the AirPlay buttons wings, it will no longer occasionally fly around the screen

### 6.0 Build 361:
- Fixed an issue where scrolling in lists could show cells half swiped over
- Fixed an issue where show notes where getting rendered too often, stealing your precious battery power
- Big(ish) code clean up to get rid of old cruft
- Implemented new incoming share link handling (eg: for opening things like http://pca.st/material)
- Fixed: If you press and hold on podcast cover art in the grid view the cover art doesn't grow in size to indicate that I can rearrange it
- New filter icons
- New top level icons
- Fixed: The colour behind played progress for the episode buttons in the rows is too light

### 6.0 Build 360
- Removed 1px divider that was on the RHS of base iPhone page
- Podcast page download buttons now use correct color when on the dark theme
- Show embedded artwork option moved to the Appearance section
- Mini player is now darker in the dark theme
- Fixed Download Assistant offsets when the mini player is visible
- Fixed an issue where the main screen on iOS was scrolled down on first launch
- Proper picture-in-picture icon added for iPad
- Dark Theme fixes for iPad Settings
- Dark theme applied to the Discovery section
- Fixed: If you try to mark an episode that's currently downloading as played (using the swipe gesture) the row flickers back and forth
- Fixed: Podcast settings popup has two settings that are cut off on the right
- Fixed: 'Start Episodes From' podcast setting was cut off on the 4S/5S/SE
- Fixed: tapping on the mini player when in up next mode now goes to the up next list in the full screen player
- Fixed: Mini player re-arrange bug where episodes would be left hanging in the air
- Fixed: Mini player re-arrange bug where the episode would change size as you drag it between episodes

### 6.0 Build 359
- Picture in Picture support added for iPads that support it
- Slightly bigger settings icons
- Stats icons added
- Exposed hidden theme support to see what people think (note: this is experimental and some places won't look right. Please don't report Dark Theme bugs for now. Yes it's been there for a while and we never told you. MU HA HA HA HA)

### 6.0 Build 358
- Added settings icons
- Fixed some issues from the previous build and the Effects player knowing where you're up to

### 6.0 Build 357
- Fixed: If you drag the mini player up you can't drag it back down or dismiss it at all.
- Fixed: You can now scrub/skip an episode while it's paused
- Cleaned up/improved the way the Effects player (remove silence, volume boost player) does skipping and reporting it's current position

### 6.0 Build 356
- Airplay icon is now tappable, it also no longer flies across the screen (Imma miss that feature)
- Grid size changing now works again

### 6.0 Build 355
- Fixed podcast list/grid crash
- Pull to refresh fixes

### 6.0 Build 354
- Fixed 3D touch shortcuts crashing when you used them (instead of, you know, taking you to where you wanted to go)
- Potential fix for a bug where the app would crash while you were on the podcast grid
- Added new options under Storage. You can now quickly delete downloaded files and also clear the iOS system cache. Ssshhh no one tell a certain fruit company.

### 6.0 Build 353
- Fixed: Tapping a link from the episode then tapping 'Done' in Safari causes you to come back to a weird black screen
- First cut of new pull to refresh animation (not finished yet, but you can use it)

### 6.0 Build 352
- iPad now playing page implemented
- Up Next button added to iPad mini player
- Now playing page now works correctly on an iPhone 4S
- Fixed: almost all the pages under iPad settings now open to the correct size (except syncing)
- Fixed an issue where rotating the podcast grid would result in cells being resized wrong
- Fixed an issue where the 'Syncing Podcasts' dialog would appear on the podcast list page
- Fixed: not enough room for the mini player on the main iPhone page
- Fixed an issue where the app was a little too eager to clear out what you're playing because it thought the app was crashing
- Fixed (iPad): When there's nothing playing, there'll be a blank spot down the bottom where the mini player is, this is not intentional

### 6.0 Build 350
- Title bar colour tweak
- Changed the playlist options button icon to match other options buttons in the app
- Fixed: long pressing the play/download button in an episode list on iPad crashes the app
- Fixed: iPad mini player long episode title could run over the rest of the controls, especially when shrunk down
- Fixed: put the proper assets in the for the iPad mini player buttons. All nice and high-res now
- Attempted fix for player loading with 00:00 - 00:00 and the scrubber bar in the middle

### 6.0 Build 349
- Fixed dragging an episode filter below the add new filter button crash
- Fixed crash when tapping on menu button on iPad episode card
- Fixed: Download all on filter page crashes app
- Stats page implemented (icons missing though)
- Tweaked Filter colours
- Added dialogs back into the syncing page for register, sign in, etc
- Syncing workflow for iPhone hooked back up (sign into sync -> get taken to podcast page with progress dialog)
- Fixed: The player lets you turn on Audio Effects like Trim Silence while playing a video. Doing so then pressing play/pause causes the video not to play
- Fixed: Unsubscribing to a podcast while 1) the podcast is in now playing status and 2) paused causes the next podcast to start playing

### 6.0 Build 347
- Open an episode card: you can still use the swipe back gesture to move the UI in the background
- When the Now Playing screen is open, you can swipe at the very top to go back a level in the page below it even though it's not visible
- Implemented no search results/search error for Discovery search
- Implemented Chromecast (Google Cast) support
- Implemented buffering state for the full screen player when casting (missing in/out animation)
- Fixed: Chapters don't load when the app first opens until you tap play

### 6.0 Build 346
- Implemented show older episodes
- Fixed: pressing pause when using effects shows the playback position as 0
- Fixed: pressing pause then play when using effects sometimes goes back a few seconds
- Implemented Sleep Timer
- Fixed: podcast and episode filters cell bleed into each other by 1pt
- Fixed: When you tap on a link in the full screen player and press done, there's an overlay over the whole interface

### 6.0 Build 345
- Video skip forward button now shows correct time
- Fixed: You can see buttons behind the video player buttons when the video isn't loaded
- Fixed: Landscape video control buttons should fade out, tap to bring them back
- Fixed: If a video is paused when you open the full screen player, the spot where it goes is blank

### 6.0 Build 344
- Fixed: Top item in trending and most popular has a white font for the title and author, so it's invisible
- Fixed: Up Next page time left on the current episode doesn’t update unless you play/pause. Should update while playing
- Fixed: Play an episode with volume boost on, leave app while playing, play audio in another app, come back, PC still says you're playing
- Fixed a bug where the app could crash at the end of some shows (Under The Radar Ep 12 being one)
- Fixed: if you go to the podcast page, then back, the open the full screen player and pull down slowly, you can see the navigation bar is above the dimmed background view so it's bright red
- Fixed: Don't show file size on button if there isn't one, ditto for length
- Fixed: Tap to dismiss effects page missing
- Fixed: Trim Silence should show you a counter when you turn it on so you can see it working
- Landscape support:
  - Mini Player now supports all orientations
  - Discover section now rotates properly (Featured and Networks have minor issues in landscape still)
  - Now playing page for audio
  - Podcast page
  - Video player
  - Podcast grid has some odd rotation spacing issues

### 6.0 Build 343
- Fixed: here's a bug where if you go to podcast settings and press the minus button on the Start Episode From item it resets to 0sec no matter what the previous value was. If it was 30 sec, press minus button, changes to 0sec.
- Starred episodes no longer backed up by iCloud, also fixed a related bug
- Trying out allowing images to load in show notes
- Newly added podcasts now have the correct sort order set
- Fixed a bug where if the podcast ended while the app was in the background, when you came back the player was still up
- Added AAC/M4A chapter support
- New mini player design
- You can now mark the episode you are playing as played from the now playing Up Next page
- Tweaked design of top/trending charts
- Tweaked show notes design
- Implemented full screen Up Next (remove, etc)
- Implemented proper effects panel (noise removal removed [HAH! GET IT], volume boost now a single button, silence removal now a slider)
- Implemented save per podcast or save globally for audio effects
- Tweaked airplay icon
- Fixed: when you pull down on the podcast tiles page, and change to the table view, it's collapsed

### 6.0 Build 342
- Less jagged mini player artwork
- Fixed up next list empty font colour
- Nearby option in discover section removed
- Playback speeds are now set properly so you don't end up playing at 0.99998x
- Fixed a bug where if you try to skip past the end of a podcast the entire app could lock up
- Fixed some performance issues while the app is backgrounded
- Fixed: Now Playing page should refresh on app wake up (sometimes shows the wrong play state when you reopen the app)
- Implemented keep screen awake setting
- Updated Episode Card Design
- Added Airplay button to now playing page

### 6.0 Build 341
- Improved colour picking algorithm
- Fixed the colour of the progress bar on the now playing page being chosen wrong
- Player now updates properly when you change from one episode to another while it's open
- The top of the full screen player no longer bleeds into the mini player
- Fixed: Video podcasts don't keep playing if you background the app, they should continue as audi
- Updating internal libraries
- Changed some things to make figuring out crashes easier

### 6.0 Build 340
- Trying out a different design for the Now Playing page (I know the mini player has a pull down artefact thing on it, haven't updated it yet)
- Warn when not on Wifi setting was working the opposite way it was meant to (LOL)
- Implemented Download Manager list headings
- Implemented Download Manager failed episode state
- Implemented Download Manager swipe to mark as played

### 6.0 Build 339
- [Discover Section] Subscribe button for the first show in the top chart is now visible
- [Discover Section] Subscribe buttons now update properly when you subscribe to a podcast
- [Discover Section] Added tap support for podcasts in the networks section
- Mini player no longer shows up in the Discover section when loaded from the podcast list page
- Fixed residual issues with play/pause/skip from headphones/apple watch
- Fixed issues with searching the grid/list view of podcasts and the top bit jumping around
- Fixed keyboard not being dismissed when you scroll back up the list of podcasts after a search

### 6.0 Build 338
- Long podcast names bleed into episode artwork on the filter pages
- When playing with audio effects on, the player doesn't pause for phone calls
- On smaller phones the Episode Popup time overlaps the icon http://d.pr/i/3VtY
- When you have a mini player loaded opening the app settings shows a black status bar instead of a white one
- Added list view implementation (third button when choosing small grid -> large grid -> list) that in the current build does nothing
- Mini player now shows a message when your Up Next list is empty
- Long press on the mini player now works properly
- Attempted fix for bluetooth pause not working, not sure if it will work, couldn't reproduce
- App now supports pausing for navigation instead of having it duck so that you miss your podcast
- Fixed an issue where if you had an up next list, when you got to the end of an episode, that was added to it. Oops.

### 6.0 Build 337
- Fixed a bug where the auto download 'Use Mobile Data' switch was being ignored
- Fixed a bug where the app would sometimes not re-instate your playback speed on play/pause
- Couldn't figure out the audio distortion issue a few people have reported, but this build may help if my theory about it is correct

### 6.0 Build 336
- Fixed podcast start from time not being able to be set back to 0 after setting it higher
- Fixed: Using any of the audio effects while the player is paused can result in it crashing
- Added pink text to Audio Effects panel just to make it clear it's a place holder :)

### 6.0 Build 335
- Implemented Download All on Podcast page
- Implemented Mark All As Played on Podcast page
- Implemented Mark All As Unplayed on Podcast page
- Remove an episode from the "up next" list by marking it as played -> Swipe left on mini player, the icon of the episode just got deleted still there -> Click it -> Crash
- Fixed: Swipe down the full screen player while playing a video, the mini player is not there
- Implemented 'Download All' on the Episode Filter page
- Implemented 'Play all from here' on the Episode Filter page
- Tapping play on an episode when you've built an Up Next list no longer loses 1 episode
- Long press on play button in an Episode Filter -> 'Play all from here' now works
- Long press on play button on Podcast page -> 'Play all from here' now works

### 6.0 Build 334
- Implemented download settings in Download Assistant

### 6.0 Build 333
- Added support for portrait video
- New download error messages
- Downloading episodes now appear in all filters, regardless of setup
- Download Assistant icon now shows number of downloads

### 6.0 Build 302
- New Certificates
- Added down states for skip buttons
- Added down state for play/pause
- Fixed: skip buttons missing numbers
- Fixed: Base page now has a title instead of an icon
- Fixed: Episode not being marked as played when it ends and there's another one in Up Next
- Fixed: You can no longer pan the page in the slider drag area

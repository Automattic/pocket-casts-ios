### 7.20

#### 881
- Make the delete folder button to fill the whole row (#79)
- Limit folders to 100 chars (#80)
- Fix an issue where the sort order was ignoring the search text when creating a folder (#81)

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

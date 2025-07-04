# CHANGELOG

## 4.2.0+57

- Introduced message-based reporting and moderation system
- Implemented dynamic user reputation scoring
- Refined user permissions for better safety and control
- Added extra protection for new female users
- Re-enabled group chat functionality
- Introduced categories for group chats and contacts
- Added support for inviting followers to group chats
- Optimized performance by hiding read messages by default
- Added pull-to-refresh support throughout the app
- Updated dependencies for improved stability and compatibility

## 4.1.0+56

- Disable group chat functionality until a stronger moderation system is ready

## 4.0.0+55

- Introduced group chat functionality
- Enforced additional restrictions for low-level users
- Enhanced page efficiency
- Resolved various bugs

## 3.9.1+54

- Fixed a bug that would corrupt user records during recovery token generation
- Cleared all notifications when app enters foreground
- Improved performance when deleting chats
- Fixed various other bugs

## 3.9.0+53

- Enabled account restoration using a recovery token
- Displayed a "What’s New" page after app upgrades
- Renamed "Description" to "Self Introduction"
- Fixed a layout issue that caused some pages to overflow
- Fixed various other bugs

## 3.8.1+52

- Fixed an annoying bug that prevented the read message count from being updated
- Notified all partners in active chats when a user was reported and confirmed

## 3.8.0+51

- Added a Recall button to the context menu for messages and images
- Added a Copy button to the context menu for messages
- Updated the friends indicator with a new icon
- Upgraded dependencies

## 3.7.0+50

- Implemented caching for network images to improve performance

## 3.6.0+49

- Added a scheduled task to remove inactive users and their associated records
- Introduced a verification step to ensure a logged-in user still exists
- Fixed a bug that prevented user info from being cached properly
- Updated the scheduled task to delete chats immediately upon expiration
- Enhanced the input field to display help text when disabled

## 3.5.0+48

- Added a new push notification payload variable for limiting message ranges
- Enhanced push notification mechanism to remove invalid FCM tokens
- Introduced an initialization step to ensure current user is ready before proceeding
- Optimized the main method to offload heavy initialization tasks

## 3.4.3+47

- (what's in 3.4.2+46)
- Disabled the Add and Remove User buttons while processing
- Added a null check for the user when displaying the Users page
- Added a loading indicator while fetching users
- Updated dependencies

## 3.4.2+46 (rejected)

- Fixed a persistent issue where outdated messages from a previous chat were displayed
- Resolved a UI bug that caused the friend indicator to appear in the wrong location

## 3.4.1+45

- Fixed an issue where new message might be counted incorrectly
- Prevented interface overflow caused by long usernames
- Prevented multiple tapping on the Add and Remove User buttons
- Updated help text on Friends page to explain how to add friends

## 3.4.0+44

- Added support for adding and removing friends
- Fixed a bug where the first message's push notification might be skipped
- Resolved an issue where outdated messages from the local cache were displayed
- Optimized performance for retrieving user information

## 3.3.0+43

- Make sending the first message faster and more reliable
- Fix discrepancy in the total and read message counts
- Add French to the language selection
- Update dependencies

## 3.2.6+42

- Invalidate the message cache dynamically based on active chats
- Add animated alerts and warning boxes for better visibility
- Indicate closed chats by updating the input field placeholder
- Reposition the user level tag to the right of the gender and language labels

## 3.2.5+41

- Display user level and device language on profile page
- Clear message cache for inactive chats
- Improve admin reports page

## 3.2.4+40

- Increase the suspension time for repeatedly reported users
- Display experience level to help determine user credibility

## 3.2.3+39

- Remind users not to give out personal information to strangers
- Protect new female users from harassment by some people
- Update dependencies

## 3.2.2+38

- Fix a serious problem that causes incorrect user query range
- Remind reported users to be respectful of others
- Prevent abusive users from starting new chats

## 3.2.1+37

- Persist the gender and language filters

## 3.2.0+36

- Add drop-down menus to select user gender and language

## 3.1.0+35

- Restore a dismissed chat using the undo button
- No longer provide defaults for the profile form

## 3.0.10+34

- Combine steps in the setup wizard
- Provide a default profile for new users

## 3.0.9+33

- Fix a bug that allows multiple taps on the Say Hi button
- Exclude abusive users from the Active Users page
- Prevent abusive users from reporting others
- Prevent misbehaving users from chatting with others

## 3.0.8+32

- Fix a bug that causes mismatched list items after reordering
- Display the content of a user or chat item in multiple lines
- Hide info banners in user and chat lists after closing
- Upgrade dependencies

## 3.0.7+31

- Improve the manual report resolution mechanism
- Reduce the number of users in the top users list

## 3.0.6+30

- Add info banners to remind people to report inappropriate content
- Add an automatic report resolution mechanism in addition to manual resolution
- Improve performance by adding some caching
- Work around the non-ASCII encoding problem

## 3.0.5+29

- Display alerts for users reported for offensive messages
- Display warnings for users reported for inappropriate behavior

## 3.0.4+28

- Fix a bug that would cause the Users page to be blank

## 3.0.3+27

- Remind people to stay away from those who have been reported

## 3.0.2+26

- Make active users easier to find by moving them up in the list

## 3.0.1+25

- Tap the avatar to view user info on the Users and Chats pages

## 3.0.0+24

- Add a setup wizard
- Add a bottom navigation bar
- Make data fetching more efficient
- Upgrade dependencies

## 2.0.5+23

- Add a report button to comply with the Child Safety Standards policy

## 2.0.4+22

- Greet everyone on the list with one tap

## 2.0.3+21

- Request push notification permission with a custom dialog
- Navigate to specific chats when notifications are tapped

## 2.0.2+20

- Fix a bug where new message count could be negative
- Update layout of the home page
- Updating user profiles is no longer mandatory
- Don't request for push notification permissions
- Update dependencies

## 2.0.1+19

- Fetch users in reversed timestamp order

## 2.0.0+18

- Chat in private rooms
- Send push notifications

## 1.4.0+17

- Now people can share pictures

## 1.3.0+16

- Let the chatbot join a conversation where no one is responding

## 1.2.2+15

- Let people know they can chat in their own languages
- Display language names in the Rooms page title

## 1.2.1+14

- Hide rooms after visiting them on the Rooms page
- Hide rooms that the user has not replied to on the Recents page
- Remove recent rooms based on their updated timestamp
- Flag rooms with new messages on the History page

## 1.2.0+13

- Display a list of rooms for user selection

## 1.1.2+12

- Guide users to set a topic for new chat rooms

## 1.1.1+11

- Change the wording of the help messages
- Update dependencies

## 1.1.0+10

- Swipe to dismiss recent rooms

## 1.0.2+9

- Increase test coverage
- Upgrade dependencies

## 1.0.1+8

- Merge only messages sent consecutively within a short period of time

## 1.0.0+7

- Add support for the predictive back gesture
- Get instant feedback on message delivery even when offline
- Set up centralized error handling to improve robustness

## 0.6.0+6

- Make sure we get a different user profile on clicking the refresh button

## 0.5.0+5

- Adjust the data model to support customizing chat room titles

## 0.4.0+4

- Enable keyboard shortcut `Cmd+Enter` or `Ctrl+Enter` for sending messages

## 0.3.0+3

- Make message text selectable
- Show snack bar messages only when necessary

## 0.2.0+2

- Merge adjacent messages by same sender
- Enable offline capabilities of the database
- Update dependencies

## 0.1.0

Initial release

# TransTracks-iOS
TransTracks is a transition tracking application made specifically for Transgender people. Is is based mostly around photo tracking at the moment.

The purpose of this repository is to help the community work together to improve the application.

## Preparing for development

1) Set up a Firebase project to use during development
1) Download the `GoogleService-Info.plist` file from the app settings page in the Firebase console
1) Place the `GoogleService-Info.plist` file in the TransTracks folder
1) Make a copy of the `config.plist.example` file called `config.plist`
1) Make a copy of the `InfoConfig.plist.example` file called `InfoConfig.plist`

### Optional if checking Twitter login or account creation

1) Create a Twitter developer application
1) Replace the `twitterkit-yourAppKey` in the `InfoConfig.plist` file with

### Optional if checking Google login or account creation

1) Enable Google auth in the Firebase console for your Firebase project
1) Replace the `com.googleusercontent.apps.yourClientId` in the `InfoConfig.plist` file with the `REVERSED_CLIENT_ID` value from the `GoogleService-Info.plist`

## Contributing

If you are looking to help contribute but are not sure on what to work on please take a look at the issues for ideas.

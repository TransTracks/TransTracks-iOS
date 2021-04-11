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

## License

```
Copyright (C) 2018 - 2021 TransTracks

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```

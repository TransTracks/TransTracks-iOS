# TransTracks-iOS

> **This project is archived and no longer maintained.** TransTracks has been retired from the App Store, and the source here is no longer being updated. Issues and pull requests are disabled. If you had the app installed and want to recover your data, see [Recovering your data](#recovering-your-data-if-the-app-was-on-your-phone) below.

TransTracks was a transition tracking application made for transgender people, focused on photo-based progress tracking.

## Project status

No new features, no bug fixes, no pull requests being reviewed, no issues being triaged. The code is preserved here for reference and so former users can recover their data. For data recovery, see the section below.

## Recovering your data if the app was on your phone

TransTracks has been retired from the App Store. I can't republish the app or hand out installs, so reinstalling isn't an option.

The good news is that if you still had the app installed when it was removed from the store, your data is almost certainly still on your phone. iOS "offloads" retired apps, which means the binary gets removed but your sandbox stays behind. Getting it out takes a few steps but it's doable on your own.

Your entries were stored in a local [Realm](https://realm.io/) database. Here's how to recover it:

1. Plug your iPhone into a Mac or PC and make a full **encrypted** backup. On a Mac use Finder (right click your device, choose "Back Up Now", and tick "Encrypt local backup"). On Windows use iTunes. The encrypted part matters, unencrypted backups skip app data.

2. Install [iMazing](https://imazing.com/) (the free trial is enough for one extraction) or a similar tool like iExplorer, and point it at the backup you just made.

3. Browse into the TransTracks app container and look inside the `Documents` folder for a file ending in `.realm`. Copy that file to your computer.

4. Download [Realm Studio](https://github.com/realm/realm-studio/releases). It's free and it opens `.realm` files directly. You'll be able to read every entry, date, and photo reference the app ever saved. You can also export the data to CSV or JSON if you want to move it somewhere else.

If you had TransTracks on an Android device, see the [TransTracks-Android repo](https://github.com/TransTracks/TransTracks-Android) for its recovery instructions. The Android app stored its data differently and the steps are not the same.

I'm unfortunately not able to do one-on-one troubleshooting on this, so I really hope the steps above get you there. Good luck!

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

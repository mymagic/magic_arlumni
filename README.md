# MaGIC ARlumni

MaGIC ARlumni is an AI/ML-powered app that recognize and display information about MaGIC Alumni Startups displayed at the Alumni Wall located on the Ground Floor of MaGIC Cyberjaya. The application was built on Flutter

- [Google Play Store](https://play.google.com/store/apps/details?id=com.magic.arlumni_flutter)

<p align="center"><img src="images/anigif.gif" alt="MaGIC" width="25%"/></p>

# Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

Here's what you need to install and run the application on your local machine/device:

<p float = "center"><a href="https://developer.android.com/studio"><img src="images/androidstudio.jpg" alt="android studio" width="15%"/></a><a href="https://code.visualstudio.com/"><img src="images/vscode.jpg" alt="android studio" width="15%"/></a>
<a href="https://flutter.dev/docs/get-started/install"><img src="images/flutter.jpg" alt="android studio" width="15%"/></a> </p>


``` 
- Android Studio
- Visual Studio Code (optional but recommended)
- Flutter SDK and Dart installed
- Sign Up at https://magic.cloud.tyk.io/portal/ for credential key
```

# Installing

Get the key from https://magic.cloud.tyk.io/portal/ first then start cloning or downloading the repo, inside your prefered IDE (Visual Studio Code or Android Studio) terminal, create cred.dart file at

```
auth/cred.dart
```
and then paste the following:

```
final String apiKey = "paste_your_key_here";
```

then, after grabbing the key from https://magic.cloud.tyk.io/portal/ do paste it inside the "paste_your_key_here"

then from the terminal, run

```
flutter pub get
flutter run
```

the application should up and running!

# Deployment

- [Build and release an Android app](https://flutter.dev/docs/deployment/android)
- [Build and release an iOS app](https://flutter.dev/docs/deployment/ios)

## Built With

#### Flutter : Mobile UI Framework‎

- [Flutter](https://flutter.dev/) 

#### Flutter Packages
- [Camera](https://pub.dev/packages/camera)
- [LineIcons](https://pub.dev/packages/line_icons) 
- [material_design_icons_flutter](https://pub.dev/packages/material_design_icons_flutter)
- [path_provider](https://pub.dev/packages/path_provider)
- [http](https://pub.dev/packages/http)
- [progress_hud](https://pub.dev/packages/progress_hud)
- [splashscreen](https://pub.dev/packages/splashscreen)
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)
- [flutter_linkify](https://pub.dev/packages/flutter_linkify)
- [url_launcher](https://pub.dev/packages/url_launcher)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [transformer_page_view](https://pub.dev/packages/transformer_page_view)
- [cupertino_icons](https://pub.dev/packages/cupertino_icons)

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning.

## Authors

* [**Darren Tan**](https://www.linkedin.com/in/daren-tan/)
* [**Hasbullah**](https://www.linkedin.com/in/mohd-hasbullah-mohd-nor-121a3895/)
* [**Ahmad Siraj MY**](https://github.com/asmyio)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgements

Thank you everyone who did contribute for this app in one way or another, hat tip to anyone whose code was used and may the force be with you.
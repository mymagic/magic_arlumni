import 'dart:async';
import 'home.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(
    MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
            seconds: 1,
            navigateAfterSeconds: await checkFirstSeen(firstCamera),
            imageBackground: new AssetImage('assets/images/splash.png'),
            backgroundColor: Colors.white,
            styleTextUnderTheLoader: new TextStyle(),
            photoSize: 100.0,
            loaderColor: Colors.red)),
  );
}

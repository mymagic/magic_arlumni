import 'package:flutter/material.dart';
import 'package:arlumni_flutter/model/yudiz_modal_sheet.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:progress_hud/progress_hud.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'auth/cred.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  static const platform = const MethodChannel('com.mymagic.arlumni/helper');
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // Startup Details Values
  static var _startupName = "";
  static var _confidenceLvl = "";

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.high,
      enableAudio: false,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();

    // Initialize firebase stuff
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      key: _scaffoldKey,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return new GestureDetector(
                onTap: () => _capture(),
                child: Stack(
                  alignment: FractionalOffset.center,
                  children: <Widget>[
                    new Positioned.fill(
                        child: new AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    )),
                    new Positioned.fill(
                      child: new Opacity(
                        opacity: 0.3,
                        child: new Image.asset("assets/images/frame.png"),
                      ),
                    ),
                    new Positioned.fill(child: _progressHUD),
                  ],
                ));
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: new FloatingActionButton(
        backgroundColor: Color(0x9671000d),
        onPressed: showInfoMenu,
        tooltip: 'Increment',
        child: new Icon(Icons.info, color: Colors.white),
      ),
    );
  }

  void _capture() async {
    // Take the Picture in a try / catch block. If anything goes wrong,
    // catch the error.
    try {
      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      // Construct the path where the image should be saved using the
      // pattern package.
      final path = join(
        // Store the picture in the temp directory.
        // Find the temp directory using the `path_provider` plugin.
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      await _controller.takePicture(path);

      var result;
      await _getStartupFromBitmap(path);
      if (_startupName != "") {
        _progressHUD.state.show();
        result = await _getStartupAlumniInfo(_startupName);
        _progressHUD.state.dismiss();
      }
      if (_startupName != "") {
        showBottomSheet(result, _confidenceLvl);
      }
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  static final _progressHUD = new ProgressHUD(
    backgroundColor: Colors.black12,
    color: Colors.white,
    containerColor: Color(0x9671000d),
    borderRadius: 5.0,
    text: 'Loading...',
    loading: false,
  );

  static final chatBubbleGradient = const LinearGradient(
    colors: const [Color(0xFFFD60A3), Color(0xFFFF8961)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  Widget userName(name, conf) {
    return Column(children: <Widget>[
      Container(
          padding:
              EdgeInsets.only(left: 20.0, right: 20.0, top: 0.0, bottom: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          )),
      Container(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        height: 30.0,
        width: 80.0,
        decoration: BoxDecoration(
            gradient: chatBubbleGradient,
            borderRadius: BorderRadius.circular(30.0)),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Icon(
                // user.gender == 'M' ? LineIcons.mars : LineIcons.venus,
                MdiIcons.imageFilterCenterFocusWeak,
                color: Colors.white,
              ),
              Text(
                conf.toString() + "%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              )
            ],
          ),
        ),
      )
    ]);
  }

  Widget cardTitle(text) {
    return Container(
        margin: EdgeInsets.only(top: 20.0),
        padding: EdgeInsets.only(left: 20.0, right: 20.0),
        child: Column(
          children: <Widget>[
            Text(
              text,
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ));
  }

  Widget startupDescription(key, value, name, conf) {
    return Container(
      margin: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 5.0),
      // width: deviceWidth,
      decoration: BoxDecoration(
        // borderRadius: BorderRadius.circular(12.0),
        color: Colors.white,
      ),
      // constraints: BoxConstraints(minHeight: 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          userName(name, conf),
          SizedBox(
            height: 5.0,
          ),
          Text(
            key,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 2.0,
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
            ),
          )
        ],
      ),
    );
  }

  Widget startupDetails(key, value) {
    return Container(
      margin: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 5.0),
      // width: deviceWidth,
      decoration: BoxDecoration(
        // borderRadius: BorderRadius.circular(12.0),
        color: Colors.white,
      ),
      // constraints: BoxConstraints(minHeight: 100.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 5.0,
          ),
          Container(
              constraints: BoxConstraints(minWidth: 70.0),
              child: Text(
                key,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              )),
          SizedBox(
            width: 20.0,
          ),
          Flexible(
              child: key == "Website"
                  ? Linkify(onOpen: _onOpen, text: value)
                  : Text(value,
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                      )))
        ],
      ),
    );
  }

  Widget startupSDG(key, value) {
    return Container(
      margin: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 5.0),
      // width: deviceWidth,
      decoration: BoxDecoration(
        // borderRadius: BorderRadius.circular(12.0),
        color: Colors.white,
      ),
      // constraints: BoxConstraints(minHeight: 100.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 5.0,
          ),
          Container(
              constraints: BoxConstraints(minWidth: 70.0),
              child: Text(
                key,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              )),
          SizedBox(
            width: 20.0,
          ),
          _getImage(value),
        ],
      ),
    );
  }

  Image _getImage(String strImg) {
    if (strImg != "") {
      return Image.network(
        strImg,
        height: 64.0,
      );
    } else {
      return Image.asset(
        'assets/images/placeholder.png',
        height: 64.0,
      );
    }
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  void showInfoMenu() {
    return YudizModalSheet.show(
        context: context,
        child: Container(
          decoration: BoxDecoration(
              color: Color(0xdd71000d),
              // color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15), topRight: Radius.circular(15))),
          height: MediaQuery.of(context).size.height / 5 * 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                cardTitle("App Information"),
                Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                                padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                                child: Image.asset(
                                  'assets/images/favicon.png',
                                  height: 64.0,
                                )),
                            Container(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                              child: Text(
                                "MaGIC ARlumni is an AI/ML-powered app that recognize and display information about MaGIC Alumni Startup logos. "
                                "These startups have underwent one of the many programs held here at the Malaysian Global Innovation and Creativity Center (MaGIC). "
                                "All alumni logos are displayed at the Alumni Wall located on the Ground Floor of MaGIC",
                                style: TextStyle(color: Colors.black),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                child: Image.asset(
                                  'assets/images/alumniwall.jpeg',
                                  height: 100,
                                )),
                            Container(
                                padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                                child: Text(
                                    "You can visit us at:\nMalaysian Global Innovation and Creativity Center (MaGIC), 3730, Persiaran Apec, 63000, Cyberjaya, Selangor, Malaysia",
                                    style: TextStyle(color: Colors.black),
                                    textAlign: TextAlign.center)),
                          ],
                        )))
              ],
            ),
          ),
        ),
        direction: YudizModalSheetDirection.BOTTOM);
  }

  void showBottomSheet(alumniInfo, conf) {
    // Define and process all the data here
    //  These values should never be empty
    var startupName = alumniInfo['data'][0]['title'];
    var startupDesc = alumniInfo['data'][0]['textShortDescription'];
    var locationText = alumniInfo['data'][0]['addressCountryCode'];
    var websiteText = alumniInfo['data'][0]['urlWebsite'];

    print(startupName);

    //  Check if industryName is empty
    var industry = alumniInfo['data'][0]['industries'] ?? null;
    var industryName;
    (industry != null)
        ? industryName = alumniInfo['data'][0]['industries'][0]['title']
        : industryName = "-";

    //  Check if SDG is empty
    var sdg = alumniInfo['data'][0]['sdgs'] ?? null;
    var sdgImg;
    (sdg != null)
        ? sdgImg = alumniInfo['data'][0]['sdgs'][0]['imageCoverThumbUrl']
        : sdgImg = "";

    //  Check if IndividualOrg is empty
    var individualOrg =
        alumniInfo['data'][0]['individualOrganizations'] ?? null;
    var individualList;
    (individualOrg != null)
        ? individualList = alumniInfo['data'][0]['individualOrganizations']
        : individualList = "";
    var individualListText = "";
    for (var i = 0; i < individualList.length; i++) {
      individualListText += individualList[i]['individual']['fullName'];
      if (i != individualList.length - 1) individualListText += "\n";
    }

    //  Check if eventOrg is empty
    var eventOrg = alumniInfo['data'][0]['individualOrganizations'] ?? null;
    var eventList;
    (eventOrg != null)
        ? eventList = alumniInfo['data'][0]['eventOrganizations']
        : eventList = "";
    var eventListText = "";
    for (var i = 0; i < eventList.length; i++) {
      eventListText += eventList[i]['event']['title'];
      if (i != eventList.length - 1) eventListText += "\n";
    }

    return YudizModalSheet.show(
        context: context,
        child: Container(
          decoration: BoxDecoration(
              color: Color(0x9671000d),
              // color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15), topRight: Radius.circular(15))),
          height: MediaQuery.of(context).size.height / 5 * 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                cardTitle("Startup Detected"),
                Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            startupDescription(
                                "Description", startupDesc, startupName, conf),
                            startupDetails("Country", locationText),
                            startupDetails("Website", websiteText),
                            startupDetails("Industry", industryName),
                            startupSDG("SDG", sdgImg),
                            startupDetails("Team", individualListText),
                            startupDetails("Programmes", eventListText),
                            SizedBox(
                              height: 10.0,
                            ),
                          ],
                        )))
              ],
            ),
          ),
        ),
        direction: YudizModalSheetDirection.BOTTOM);
  }

  void toast(text) {
    Widget snackBar = new SnackBar(
        content: new Text(
          text,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0x9671000d));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future<void> _getStartupFromBitmap(path) async {
    try {
      final result =
          await platform.invokeMethod('classifyImage', {"path": path});
      if (result.length != 0) {
        // Update interface
        _startupName = result[0];
        var conf = double.parse(result[1]) * 100;
        _confidenceLvl = conf.toInt().toString();
      } else {
        _startupName = "";
        toast("No startup found. Please try scanning again!");
      }
    } on PlatformException catch (e) {
      print("Failed to Invoke: '${e.message}'.");
    }
  }

  Future _getStartupAlumniInfo(name) async {
    var uri = "https://magic.cloud.tyk.io/getAlumniStartups";
    Map<String, String> header = {
      "Authorization":
          apiKey
    };
    try {
      final response = await http.post(uri, headers: header, body: {
        'searchTitle': name,
      });

      final responseJson = json.decode(response.body);
      return responseJson;
    } catch (exception) {
      print(exception);
      if (exception.toString().contains('SocketException')) {
        return 'NetworkError';
      } else {
        return null;
      }
    }
  }
}

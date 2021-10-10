import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shutter_con/CameraScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Shutter Con',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Home(),
        routes: {
          '/cameraScreen': (BuildContext context) =>
              CameraScreen(cameras: cameras),
        });
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<void> getPermissions() async {
    Permission camera = Permission.camera;
    Permission microphone = Permission.microphone;
    Permission accessMedia = Permission.accessMediaLocation;

    if (Platform.isAndroid) {
      AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      int sdk = info.version.sdkInt;
      if (sdk <= 28) {
        accessMedia = Permission.storage;
      }
      print('sdk : $sdk');
    }

    if (await camera.status.isDenied) await camera.request();
    if (await camera.status.isDenied) {
      print('camera denied');
      SystemNavigator.pop();
    }
    if (await microphone.status.isDenied) await microphone.request();
    if (await microphone.status.isDenied) {
      SystemNavigator.pop();
      print('microphone denied');
    }
    if (await accessMedia.status.isDenied) await accessMedia.request();
    if (await accessMedia.status.isDenied) {
      SystemNavigator.pop();
      print('MediaLocation denied');
    }

    Navigator.pushReplacementNamed(context, '/cameraScreen');
  }

  @override
  void initState() {
    getPermissions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

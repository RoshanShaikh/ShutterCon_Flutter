import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  final List<CameraDescription> cameras;
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  int selectedCamera = 0;
  int noOfClicks = 10;
  int clickCounter = 0;

  TextEditingController _noOfClicks = TextEditingController();

  Future<void> captureImage() async {
    while (true) {
      if (await Permission.camera.status.isDenied) {
        await Permission.camera.request();
      }
      if (await Permission.accessMediaLocation.status.isDenied) {
        await Permission.accessMediaLocation.request();
      }
      if (await Permission.accessMediaLocation.status.isGranted &&
          await Permission.camera.status.isGranted) {
        break;
      }
    }
    await _initializeControllerFuture;
    await _controller.unlockCaptureOrientation();
    await _controller.setFlashMode(FlashMode.off);

    var xFile = await _controller.takePicture();

    Directory directory = await Directory('/storage/emulated/0/DCIM/Shutter')
        .create(recursive: true);
    if (await directory.exists()) {
      print(directory.path);
      DateTime d = DateTime.now();
      String filename =
          '${d.day}${d.month}${d.year}${d.hour}${d.minute}${d.second}';
      await File(xFile.path).copy('${directory.path}/$filename.jpeg');
      print('Copied to ${directory.path}/$filename.jpeg');
    }
  }

  Future<void> switchCamera() async {
    if (widget.cameras.length > 1) {
      selectedCamera = (selectedCamera == 0) ? 1 : 0;
      await _initializeCamera(selectedCamera);
      setState(() {});
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Secondary Camera Not Found')));
    }
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    _controller = CameraController(
        widget.cameras[cameraIndex], ResolutionPreset.ultraHigh);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void initState() {
    _initializeCamera(selectedCamera);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Permission.accessMediaLocation.request();

    _noOfClicks.text = noOfClicks.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FutureBuilder(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.80,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                }
              },
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 100,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Positioned(
                    child: Text(
                      clickCounter.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                      ),
                    ),
                    bottom: MediaQuery.of(context).size.width * 0.1,
                    left: MediaQuery.of(context).size.width * 0.1,
                  ),
                  Positioned(
                    bottom: 15.0,
                    left: MediaQuery.of(context).size.width / 2 - 35.0,
                    right: MediaQuery.of(context).size.width / 2 - 35.0,
                    child: RawMaterialButton(
                      onPressed: () async {
                        clickCounter = 0;
                        for (var i = 0; i < noOfClicks; i++) {
                          print(i + 1);
                          setState(() {
                            clickCounter++;
                            print(clickCounter);
                          });
                          await captureImage();
                        }
                      },
                      elevation: 0.0,
                      constraints:
                          BoxConstraints(), //removes empty spaces around of icon
                      shape: CircleBorder(), //circular button
                      fillColor: Colors.white, //background color
                      splashColor: Colors.grey[400],
                      highlightColor: Colors.grey[400],
                      child: Container(
                        width: 70.0,
                        height: 70.0,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 15.0,
                    right: 15.0,
                    child: RawMaterialButton(
                      elevation: 0.0,
                      constraints: BoxConstraints(),
                      shape: CircleBorder(),
                      onPressed: switchCamera,
                      child: Icon(
                        Icons.change_circle,
                        color: Colors.white,
                        size: 60.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
  bool showCounter = false;
  bool readyToClick = false;

  Future<void> captureImage(String foldername) async {
    await _initializeControllerFuture;
    await _controller.unlockCaptureOrientation();
    await _controller.setFlashMode(FlashMode.off);

    var xFile = await _controller.takePicture();

    Directory directory =
        await Directory('/storage/emulated/0/DCIM/Shutter/$foldername')
            .create(recursive: true);
    if (await directory.exists()) {
      print(directory.path);
      DateTime d = DateTime.now();
      String filename = d.toString().replaceAll(RegExp(r'[- :.]'), '');
      await File(xFile.path).copy('${directory.path}/$filename.jpeg');
      print('Copied to ${directory.path}/$filename.jpeg');
    }
  }

  Future<void> switchCamera() async {
    if (!readyToClick) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.white,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.fixed,
          content: Text(
            'Can\'t Switch Camera!',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
      return;
    }
    if (widget.cameras.length > 1) {
      selectedCamera = (selectedCamera == 0) ? 1 : 0;
      await _initializeCamera(selectedCamera);
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.white,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.fixed,
          content: Text(
            'Secondary Camera Not Found!',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    _controller = CameraController(
        widget.cameras[cameraIndex], ResolutionPreset.ultraHigh);
    _initializeControllerFuture = _controller.initialize();
    readyToClick = true;
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
    RawMaterialButton shutterButton = RawMaterialButton(
      onPressed: () async {
        if (!readyToClick) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.white,
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.fixed,
              content: Text(
                'Already Capturing!',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
          print('already Capturing.');
          return;
        }

        readyToClick = false;
        clickCounter = 0;
        setState(() {
          showCounter = true;
        });

        DateTime d = DateTime.now();
        String foldername = d.toString().replaceAll(RegExp(r'[ :.]'), '-');

        for (var i = 1; i <= noOfClicks; i++) {
          await captureImage(foldername);
          showCounter = true;
          setState(() {
            clickCounter++;
            print(clickCounter);
          });
          if (i != noOfClicks)
            await Future.delayed(Duration(milliseconds: 900));
        }

        readyToClick = true;

        Timer(Duration(seconds: 2), () {
          if (readyToClick) {
            setState(() {
              showCounter = false;
            });
          }
        });
      },
      elevation: 0.0,
      constraints: BoxConstraints(), // removes empty spaces around of icon
      shape: CircleBorder(), // circular button
      fillColor: Colors.white, // background color
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
    );

    RawMaterialButton switchCameraButton = RawMaterialButton(
      elevation: 0.0,
      constraints: BoxConstraints(),
      shape: CircleBorder(),
      onPressed: switchCamera,
      child: Icon(
        Icons.change_circle_rounded,
        color: Colors.white,
        size: 60.0,
      ),
    );

    ElevatedButton changeCountButton = ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: TextField(
                onChanged: (String value) {
                  noOfClicks = int.parse(value);
                },
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  label: Text('No. Of Clicks'),
                ),
                onSubmitted: (value) {
                  Navigator.pop(context);
                },
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Done'),
                ),
              ],
            );
          },
        );
      },
      child: Text(
        noOfClicks.toString(),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FutureBuilder(
              future: _initializeControllerFuture,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      CameraPreview(_controller),
                      if (showCounter)
                        Positioned(
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35.0),
                                color: Colors.black12),
                            child: Center(
                              child: Text(
                                clickCounter.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                ),
                              ),
                            ),
                          ),
                          right: MediaQuery.of(context).size.width / 2 - 35.0,
                          left: MediaQuery.of(context).size.width / 2 - 35.0,
                          top: MediaQuery.of(context).size.height * 0.1,
                        ),
                    ],
                  );
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      changeCountButton,
                      shutterButton,
                      switchCameraButton,
                    ],
                  ),
                  // Positioned(
                  //   bottom: 15.0,
                  //   left: MediaQuery.of(context).size.width / 2 - 35.0,
                  //   right: MediaQuery.of(context).size.width / 2 - 35.0,
                  //   child: shutterButton,
                  // ),
                  // Positioned(
                  //   bottom: 15.0,
                  //   right: 15.0,
                  //   child: switchCameraButton,
                  // ),
                  // Positioned(
                  //   child: changeCountButton,
                  //   bottom: 15.0,
                  //   left: 15.0,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

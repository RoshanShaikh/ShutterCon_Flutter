import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int noOfClicks = 50;
  int clickCounter = 0;
  bool showCounter = false;
  bool readyToClick = false;

  TextEditingController _noOfClickController = TextEditingController();

  void showSnackBar(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey[200],
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.fixed,
        content: Text(
          msg,
          style: TextStyle(
            color: Colors.red,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  Future<void> captureImage(String foldername) async {
    await _initializeControllerFuture;
    await _controller.unlockCaptureOrientation();
    await _controller.setFlashMode(FlashMode.off);

    var xFile = await _controller.takePicture();

    Timer.run(
      () async {
        Directory directory =
            await Directory('/storage/emulated/0/DCIM/Shutter Con/$foldername')
                .create(recursive: true);
        if (await directory.exists()) {
          print(directory.path);
          DateTime d = DateTime.now();
          log('${d.minute}:${d.second}:${d.millisecond}');
          String filename = d.toString().replaceAll(RegExp(r'[- :.]'), '-');
          await File(xFile.path).copy('${directory.path}/$filename.jpeg');
          print('Copied to ${directory.path}/$filename.jpeg');
        }
      },
    );
  }

  Future<void> switchCamera() async {
    if (!readyToClick) {
      showSnackBar("Can't Switch While Capturing!");
      print("Can't Switch While Capturing!");
      return;
    }

    if (widget.cameras.length > 1) {
      selectedCamera = (selectedCamera == 0) ? 1 : 0;
      await _initializeCamera(selectedCamera);
      setState(() {});
    } else {
      showSnackBar('Secondary Camera Not Found!');
    }
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    _controller = CameraController(
        widget.cameras[cameraIndex], ResolutionPreset.ultraHigh);
    _initializeControllerFuture = _controller.initialize();
    readyToClick = true;
  }

  void getNoOfClicksDialog() {
    print('dialog');
    if (!readyToClick) return;
    _noOfClickController.text = noOfClicks.toString();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        _noOfClickController.selection = TextSelection(
            baseOffset: 0, extentOffset: _noOfClickController.text.length);
        return AlertDialog(
          content: TextField(
            controller: _noOfClickController,
            onChanged: (String value) {
              if (value.isNotEmpty)
                noOfClicks = int.parse(value);
              else {
                noOfClicks = 1;
                _noOfClickController.text = '1';
              }
            },
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              label: Text('No. Of Clicks'),
            ),
            onSubmitted: (value) async {
              await saveNoOfClicks();
              Navigator.pop(context);
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await saveNoOfClicks();
                Navigator.pop(context);
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveNoOfClicks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('NoOfClicks', noOfClicks);
  }

  Future<void> getNoOfClicks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? value = prefs.getInt('NoOfClicks');
    if (value != null) {
      setState(() {
        noOfClicks = value;
        _noOfClickController.text = value.toString();
      });
    }
  }

  @override
  void initState() {
    _initializeCamera(selectedCamera);
    getNoOfClicks();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    saveNoOfClicks();
    super.dispose();
  }

  Future<void> startCapturing() async {
    if (!readyToClick) {
      showSnackBar('Already Capturing!');
      print('Already Capturing.');
      return;
    }

    readyToClick = false;
    clickCounter = 0;
    setState(() {
      showCounter = true;
    });

    DateTime d = DateTime.now();
    String foldername = d.toString().replaceAll(RegExp(r'[:.]'), '-');

    for (var i = 1; i <= noOfClicks; i++) {
      await captureImage(foldername);
      showCounter = true;
      setState(() {
        clickCounter++;
        print(clickCounter);
      });
      if (clickCounter != noOfClicks)
        await Future.delayed(Duration(milliseconds: 400));
    }

    readyToClick = true;

    Timer(Duration(seconds: 2), () {
      if (readyToClick) {
        setState(() {
          showCounter = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    RawMaterialButton shutterButton = RawMaterialButton(
      onPressed: () async {
        await startCapturing();
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

    InkWell changeCountButton = InkWell(
      onTap: () {
        getNoOfClicksDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 5.0,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          border: Border.all(
            width: 1.0,
            color: Theme.of(context).primaryColor,
          ),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Text(
          noOfClicks.toString(),
          style: TextStyle(
            fontSize: 22.0,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              FutureBuilder(
                future: _initializeControllerFuture,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          child: CameraPreview(_controller),
                        ),
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
              Positioned(
                bottom: 15.0,
                child: Container(
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ffi';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_ml_kit_example/text_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

class HomePage extends StatefulWidget {
  @override
  State createState() {
    // TODO: implement createState
    return CameraWidgetState();
  }
}

class CameraWidgetState extends State {
  PickedFile? imageFile = null;
  StreamController<String> streamController = StreamController<String>();
  String? temp;
  List? pose_x;
  List? pose_y;

  List<Pose>? _poses;
  List<Face>? _faces;
  String? pos;
  CustomPaint? customPaint;
  bool isFace = false;
  bool isPose = false;
  ui.Image? _image;
  Future<void> _showChoiceDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Choose option",
              style: TextStyle(color: Colors.blue),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      _openGallery(context);
                    },
                    title: Text("Gallery"),
                    leading: Icon(
                      Icons.account_box,
                      color: Colors.blue,
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      _openCamera(context);
                    },
                    title: Text("Camera"),
                    leading: Icon(
                      Icons.camera,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("SWF ML Tutorial"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Center(
        child: ListView(
          children: [
            Card(
              child: (imageFile == null)
                  ? Text("Choose Image")
                  : Image.file(File(imageFile!.path)),
            ),
            MaterialButton(
              textColor: Colors.white,
              color: Colors.lightBlueAccent,
              onPressed: () {
                _showChoiceDialog(context);
              },
              child: Text("Select Image"),
            ),
            MaterialButton(
              textColor: Colors.white,
              color: Colors.lightBlueAccent,
              onPressed: () {
                setState(() {
                  getText(imageFile!);
                });
              },
              child: Text("Text Recognition"),
            ),
            MaterialButton(
              textColor: Colors.white,
              color: Colors.lightBlueAccent,
              onPressed: () {
                setState(() {
                  getFace(imageFile!);
                });
              },
              child: Text("Face Recognition"),
            ),
            MaterialButton(
              textColor: Colors.white,
              color: Colors.lightBlueAccent,
              onPressed: () {
                setState(() {
                  getPose(imageFile!);
                });
              },
              child: Text("Pose Recognition"),
            ),
            isFace == true
                ? SizedBox(
                    width: _image!.width.toDouble(),
                    height: _image!.height.toDouble(),
                    child: CustomPaint(
                      painter: FacePainter(_image!, _faces!),
                    ))
                : Text('Face Recognization Ready'),
            StreamBuilder(
              stream: streamController.stream,
              builder: (context, snapshot) {
                // step 4: use the streamed data
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data.toString(),
                    style: TextStyle(fontSize: 12),
                  );
                } else {
                  return Text('Text Recogniation Ready');
                }
              },
            )
          ],
        ),
      ),
    );
  }

  void _openGallery(BuildContext context) async {
    final pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
    );
    setState(() {
      imageFile = pickedFile!;
    });

    Navigator.pop(context);
  }

  void _openCamera(BuildContext context) async {
    final pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
    );
    setState(() {
      imageFile = pickedFile!;
    });
    Navigator.pop(context);
  }

  Future<String> getText(PickedFile img) async {
    final inputImage = InputImage.fromFile(File(img.path));
    final textDetector = GoogleMlKit.vision.textDetector();
    final RecognisedText recognisedText =
        await textDetector.processImage(inputImage);
    streamController.add(recognisedText.text);
    temp = recognisedText.text;
    return recognisedText.text;
  }

  Future<String> getFace(PickedFile img) async {
    final inputImage = InputImage.fromFile(File(img.path));
    final faceDetector = GoogleMlKit.vision.faceDetector();
    _faces = await faceDetector.processImage(inputImage);
    _loadImage((File(img.path)));
    isFace = true;

    return _faces.toString();
  }

  Future<void> getPose(PickedFile img) async {
    final inputImage = InputImage.fromFile(File(img.path));
    final poseDetector = GoogleMlKit.vision.poseDetector();
    _poses = await poseDetector.processImage(inputImage);
    _loadImage((File(img.path)));
    for (Pose pose in _poses!) {
      pose.landmarks.forEach((key, value) {
        print(value.x);
        print(value.y);
      });
    }
    isPose = true;
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then((value) => setState(() {
          _image = value;
        }));
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.yellow;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter old) {
    return image != old.image || faces != old.faces;
  }
}

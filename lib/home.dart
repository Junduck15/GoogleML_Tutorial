import 'dart:ffi';
import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_ml_kit_example/text_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:firebase/firebase_io.dart';
import 'package:path_provider/path_provider.dart';

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
  StreamController<String> poseStreamController = StreamController<String>();
  String? tp;
  String? temp;
  List? pose_x;
  List? pose_y;
  File? _uploadImg;
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
                uploadImage(imageFile!.path);
              },
              child: Text("Upload Image"),
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
              stream: poseStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data.toString(),
                    style: TextStyle(fontSize: 12),
                  );
                } else {
                  return Text('Pose Recogniation Ready');
                }
              },
            ),
            StreamBuilder(
              stream: streamController.stream,
              builder: (context, snapshot) {
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

  Future<void> uploadImage(String imageUrl) async {
    final firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child('MLKits') //'post'라는 folder를 만들고
        .child('${DateTime.now().millisecondsSinceEpoch}.png');

    // 파일 업로드
    final uploadTask = firebaseStorageRef.putFile(
        _uploadImg!, SettableMetadata(contentType: 'image/png'));

    // 완료까지 기다림
    await uploadTask.whenComplete(() => null);

    // 업로드 완료 후 url
    final downloadUrl = await firebaseStorageRef.getDownloadURL();
  }

  void _openGallery(BuildContext context) async {
    final pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
    );
    setState(() {
      _uploadImg = File(pickedFile!.path);
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
    tp = '';
    for (Pose pose in _poses!) {
      pose.landmarks.forEach((key, value) {
        print(value.x);
        tp = tp.toString() + value.x.toString();
        poseStreamController.add(tp.toString());
        // pose_x?.add(value.x);
        // pose_y?.add(value.y);

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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imagepuzzle/corret_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'puzzle_piece.dart';
import 'score_widget.dart';

const IMAGE_PATH = 'image_path';

void main() {
  runApp(
    ScoreWidget(
      child: MaterialApp(
        title: 'Flutter Puzzle',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final int rows = 3;
  final int cols = 3;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File _image;
  String _imagePath;
  List<Widget> pieces = [];
  SharedPreferences prefs;

  bool _overlayVisible = true;

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  void initPrefs() async {
    prefs = await SharedPreferences.getInstance();

    _imagePath = prefs.getString(IMAGE_PATH);

    if (_imagePath != null) {
      //print(_imagePath);
      _image = File(_imagePath);
      print(_image.path);
    }

    splitImage(Image.file(_image));

    // restore importanat things
  }

  void savePrefs() async {
    await prefs.setString(IMAGE_PATH, _imagePath);
  }

  Future getImage(ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _image = image;
        _imagePath = _image.path;
        pieces.clear();
        ScoreWidget.of(context).allInPlaceCount = 0;
      });
    }
    splitImage(Image.file(image));
    savePrefs();
  }

  // we need to find out the image size, to be used in the PuzzlePiece widget
  Future<Size> getImageSize(Image image) async {
    final Completer<Size> completer = Completer<Size>();

    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble()));
    }));

    final Size imageSize = await completer.future;

    return imageSize;
  }

  // here we will split the image into small pieces
  // using the rows and columns defined above; each piece will be added to a stack
  void splitImage(Image image) async {
    Size imageSize = await getImageSize(image);

    for (int x = 0; x < widget.rows; x++) {
      for (int y = 0; y < widget.cols; y++) {
        setState(() {
          pieces.add(
            PuzzlePiece(
              key: GlobalKey(),
              image: image,
              imageSize: imageSize,
              row: x,
              col: y,
              maxRow: widget.rows,
              maxCol: widget.cols,
              bringToTop: this.bringToTop,
              sendToBack: this.sendToBack,
            ),
          );
        });
      }
    }
  }

  // when the pan of a piece starts, we need to bring it to the front of the stack
  void bringToTop(Widget widget) {
    setState(() {
      pieces.remove(widget);
      pieces.add(widget);
    });
  }

// when a piece reaches its final position,
// it will be sent to the back of the stack to not get in the way of other, still movable, pieces
  void sendToBack(Widget widget) {
    setState(() {
      pieces.remove(widget);
      pieces.insert(0, widget);
    });
  }

  @override
  Widget build(BuildContext context) {
    savePrefs();

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Puzzle'),
      ),
      body: SafeArea(
        child: _image == null
            ? Center(child: Text('No image selected.'))
            : ScoreWidget.of(context).allInPlaceCount ==
                    widget.rows * widget.cols
                ? Overlay(
                    initialEntries: [
                      OverlayEntry(builder: (context) {
                        return CorrectOverlay(true, () {
                          setState(() {
                            ScoreWidget.of(context).allInPlaceCount = 0;
                          });
                        });
                      })
                    ],
                  )
                : Stack(
                    children: pieces,
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: new Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new ListTile(
                        leading: new Icon(Icons.camera),
                        title: new Text('Camera'),
                        onTap: () {
                          getImage(ImageSource.camera);
                          // this is how you dismiss the modal bottom sheet after making a choice
                          Navigator.pop(context);
                        },
                      ),
                      new ListTile(
                        leading: new Icon(Icons.image),
                        title: new Text('Gallery'),
                        onTap: () {
                          getImage(ImageSource.gallery);
                          // dismiss the modal sheet
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              });
        },
        tooltip: 'New Image',
        child: Icon(Icons.add),
      ),
    );
  }
}

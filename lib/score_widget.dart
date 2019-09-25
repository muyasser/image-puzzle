import 'package:flutter/material.dart';

class ScoreWidget extends InheritedWidget {
  ScoreWidget({Key key, Widget child}) : super(key: key, child: child);

  int allInPlaceCount = 0;

  static ScoreWidget of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ScoreWidget) as ScoreWidget;
  }

  @override
  bool updateShouldNotify(ScoreWidget oldWidget) => false;
}

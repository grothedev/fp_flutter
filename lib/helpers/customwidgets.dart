import 'package:flutter/material.dart';

/**
 * custom IconButton for AppBar to be smaller to allow room for titles. yet to see if this is a practical solution. screw it i'm doing it manually, disregard this class
 */
class AppBarButton extends Widget{
  
  Widget icon;
  Function onPressed;
  String tooltip;

  AppBarButton({this.onPressed, this.icon, this.tooltip});
  
  @override
  Widget build(){
    return IconButton(
      iconSize: 12,
      tooltip: this.tooltip,
      //icon: this.icon,
      //onPressed: this.onPressed,
    );
  }

  @override
  Element createElement() {
    // TODO: implement createElement
    throw UnimplementedError();
  }
}
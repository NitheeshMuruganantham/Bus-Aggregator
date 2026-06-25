import 'package:flutter/material.dart';

class PlatformModel {
  final String name;
  final Color color;
  final int price;
  final String deepLink;
  final String tag;

  PlatformModel({
    required this.name,
    required this.color,
    required this.price,
    required this.deepLink,
    required this.tag,
  });
}

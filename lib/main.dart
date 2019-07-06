import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'package:flutter/material.dart';

import 'state_container.dart';

void main() =>
      runApp(
       StateContainer(
         child: FrogPondApp(),
        )
      );
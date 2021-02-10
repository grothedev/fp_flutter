/*
Frog Pond mobile application
Copyright (C) 2019  Thomas Grothe

This file is part of FrogPond.

FrogPond is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

FrogPond is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Frog Pond.  If not, see <https://www.gnu.org/licenses/>.
*/



import 'package:provider/provider.dart';
import 'app.dart';
import 'package:flutter/material.dart';

import 'controllers/controller.dart';
import 'controllers/croakcontroller.dart';
import 'controllers/tagcontroller.dart';
import 'models/croakstore.dart';
import 'models/tagstore.dart';

void main() {
      print('start of main');
      runApp(
        MultiProvider(
          providers: [ //TODO should the controllers or stores be the change notifiers?
            ChangeNotifierProvider(create: (_)=>LocalCroaksStore()),
            ChangeNotifierProvider(create: (_)=>LocalTagsStore()),
            ChangeNotifierProvider(create: (_)=>Controller()),
            //ChangeNotifierProvider(create: (_)=>CroakController()),
            //ChangeNotifierProvider(create: (_)=>TagController()),
          ],
          child: FrogPondApp()
        )
      );
      print('end of main()');
}
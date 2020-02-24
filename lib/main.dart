import 'package:flutter/material.dart';

import 'page/ni_term.dart';
import 'terminal.dart';

void main(){
  Niterm.creatNewTerm();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Terminal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Niterm()
    );
  }
}

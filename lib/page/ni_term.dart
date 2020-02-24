import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef create_subprocess = Void Function(
    Pointer<Utf8> env,
    Pointer<Utf8> cmd,
    Pointer<Utf8> cwd,
    Pointer<Pointer<Utf8>> argv,
    Pointer<Pointer<Utf8>> envp,
    Pointer<Int32> pProcessId,
    Int32 ptmfd);
typedef CreateSubprocess = void Function(
    Pointer<Utf8> env,
    Pointer<Utf8> cmd,
    Pointer<Utf8> cwd,
    Pointer<Pointer<Utf8>> argv,
    Pointer<Pointer<Utf8>> envp,
    Pointer<Int32> pProcessId,
    int ptmfd);

typedef get_ptm_int = Int32 Function(Int32 row, Int64 column);

typedef GetPtmInt = int Function(int row, int column);

typedef get_output_from_fd = Pointer<Utf8> Function(Int32);
typedef GetOutFromFd = Pointer<Utf8> Function(int);

typedef write_to_fd = Void Function(Int32, Pointer<Utf8>);
typedef WriteToFd = void Function(int, Pointer<Utf8>);

typedef getfilepath = Pointer<Utf8> Function(Int32 fd);
typedef GetFilePathFromFdDart = Pointer<Utf8> Function(int fd);

class Niterm extends StatefulWidget {
  final String script;
  const Niterm({Key key, this.script}) : super(key: key);
  static List<int> terms = [];
  static void creatNewTerm() {
    var path = 'libterm.so';
    final dylib = DynamicLibrary.open(path);
    //等价于  char **argv;

    final getPtmIntPointer =
        dylib.lookup<NativeFunction<get_ptm_int>>('get_ptm_int');
    final GetPtmInt getPtmInt = getPtmIntPointer.asFunction<GetPtmInt>();
    int currentPtm = getPtmInt(50, 68);
    terms.add(currentPtm);
    final createSubprocessPointer =
        dylib.lookup<NativeFunction<create_subprocess>>('create_subprocess');
    CreateSubprocess createSubprocess =
        createSubprocessPointer.asFunction<CreateSubprocess>();
    Pointer<Pointer<Utf8>> argv = allocate(count: 1);
    argv[0] = Pointer.fromAddress(0);
    Pointer<Pointer<Utf8>> envp;
    Map<String, String> environment = {};
    environment.addAll(Platform.environment);
    environment["PATH"] =
        "/data/data/com.nightmare/files/usr/bin:" + environment["PATH"];
    envp = allocate(count: environment.keys.length + 1);
    for (int i = 0; i < environment.keys.length; i++) {
      envp[i] = Utf8.toUtf8(
          "${environment.keys.elementAt(i)}=${environment[environment.keys.elementAt(i)]}");
    }
    envp[environment.keys.length] = Pointer.fromAddress(0);
    Pointer<Int32> p = allocate();
    p.value = 0;
    createSubprocess(
        Utf8.toUtf8(''),
        Utf8.toUtf8('/system/bin/sh'),
        Utf8.toUtf8('/data/data/com.nightmare/files/home'),
        argv,
        envp,
        p,
        currentPtm);
    print(p.value);
    free(p);
  }

  @override
  _NitermState createState() => _NitermState();
}

class _NitermState extends State<Niterm> {
  List<InlineSpan> listSpan = [];
  String ptsPath = "";
  String out = "";
  Process process;
  WriteToFd writeToFd;
  @override
  void initState() {
    super.initState();
    init();
  }

  ptm() async {}
  init() async {
    //设置so库等的路径
    print(Niterm.terms);
    var path = 'libterm.so';
    final dylib = DynamicLibrary.open(path);

    final getOutFromFdPointer =
        dylib.lookup<NativeFunction<get_output_from_fd>>('get_output_from_fd');
    GetOutFromFd getOutFromFd = getOutFromFdPointer.asFunction();
    final writetofdpointer =
        dylib.lookup<NativeFunction<write_to_fd>>('write_to_fd');
    writeToFd = writetofdpointer.asFunction();
    Future.delayed(
      Duration(seconds: 1),
      () {
        if (widget.script != null) {
          for (String a in widget.script.split("")) {
            writeToFd(Niterm.terms.first, Utf8.toUtf8(a));
          }
        }
      },
    );
    while (true && Niterm.terms.isNotEmpty) {
      // Utf8.fromUtf8(string)
      Pointer resultPoint = getOutFromFd(Niterm.terms.first);
      if (resultPoint.address != 0) {
        String result = Utf8.fromUtf8(resultPoint);
        if (result.startsWith("\b")) {
          out = out.substring(0, out.length - 1);
          setState(() {});
        } else {
          out += result;
          // if (!result.contains(String.fromCharCodes([27, 91]))) {
          //   out = result;
          //   listSpan.add(
          //       TextSpan(style: TextStyle(color: Colors.white), text: out));
          // } else {
          //   for (String a in result.split(String.fromCharCodes([27, 91]))) {
          //     print(a);
          //     listSpan
          //         .add(TextSpan(style: TextStyle(color: Colors.red), text: a));
          //   }
          // }
          setState(() {});
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
          Future.delayed(Duration(milliseconds: 300), () {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          });
        }
        // print(out);
      }
      free(resultPoint);
      await Future.delayed(Duration(microseconds: 0));
    }
  }

  @override
  void didUpdateWidget(Niterm oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback(_onAfterRendering);
    super.didUpdateWidget(oldWidget);
  }

  void _onAfterRendering(Duration timeStamp) {
    Future.delayed(Duration(seconds: 1), () {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  TextEditingController editingController = TextEditingController();
  FocusNode focusNode = FocusNode();
  String str = "";
  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    listSpan = [];
    for (String a in out.split(String.fromCharCodes([27, 91]))) {
      if (a.startsWith(RegExp("[0-9];"))) {
        String colorNumber = a.split(";")[1].substring(0, 2);
        // if(colorNumber)
        print(a);
        if (colorNumber == "34")
          listSpan.add(
            TextSpan(
              text: a.replaceAll(RegExp("^.*$colorNumber\m"), ""),
              style: TextStyle(color: Colors.lightBlue),
            ),
          );
        else if (colorNumber == "32")
          listSpan.add(
            TextSpan(
              text: a.replaceAll(RegExp("^.*$colorNumber\m"), ""),
              style: TextStyle(color: Colors.lightGreenAccent),
            ),
          );
        else if (colorNumber == "36")
          listSpan.add(
            TextSpan(
              text: a.replaceAll(RegExp("^.*$colorNumber\m"), ""),
              style: TextStyle(color: Colors.greenAccent),
            ),
          );
        else if (colorNumber == "0m")
          listSpan.add(
            TextSpan(
              text: a.replaceAll(RegExp("^.*$colorNumber\m"), ""),
              style: TextStyle(color: Colors.white),
            ),
          );
      } else {
        listSpan.add(TextSpan(text: a.replaceAll(RegExp("^m"), "")));
      }
    }
    // out = out.replaceAll(String.fromCharCodes([27, 91]), "");
    // for (String a in out.split("\n")) {
    //   if (a.startsWith(String.fromCharCodes([27, 91])) &&
    //       a.endsWith(String.fromCharCodes([27, 91, 109, 13]))) {
    //     // print(a.codeUnits);

    //     print(a);
    //   }
    // }
    return MaterialApp(
      home: WillPopScope(
        child: Scaffold(
          resizeToAvoidBottomPadding: true,
          backgroundColor: Color(0xff073542),
          body: SafeArea(
            child: GestureDetector(
              onTap: () {
                focusNode.unfocus();
                FocusScope.of(context).requestFocus(focusNode);
                scrollController
                    .jumpTo(scrollController.position.maxScrollExtent);
              },
              child: ListView(
                controller: scrollController,
                cacheExtent: 3000,
                padding: EdgeInsets.only(left: 2, bottom: 0.0, top: 0.0),
                children: <Widget>[
                  // Text(out, style: TextStyle(color: Colors.white)),
                  RichText(
                    text: TextSpan(
                      text: "",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      children: listSpan +
                          [
                            // TextSpan(text: "\n" + out),
                            TextSpan(
                                text: "▉", style: TextStyle(color: Colors.grey))
                          ],
                    ),
                  ),
                  SizedBox(
                    height: 4.0,
                    child: TextField(
                      controller: editingController,
                      autofocus: true,
                      keyboardType: TextInputType.text,
                      focusNode: focusNode,
                      style: TextStyle(color: Colors.transparent),
                      cursorColor: Colors.transparent,
                      showCursor: true,
                      cursorWidth: 0,
                      scrollPadding: EdgeInsets.all(0.0),
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        alignLabelWithHint: true,
                        border: InputBorder.none,
                        hasFloatingPlaceholder: false,
                      ),
                      onChanged: (r) {
                        if (r.length > str.length) {
                          writeToFd(Niterm.terms.first, Utf8.toUtf8(r.replaceAll(str, "")));
                        } else {
                          writeToFd(Niterm.terms.first, Utf8.toUtf8("\b"));
                        }
                        str = r;
                        // File(ptsPath).writeAsString(
                        //     r.replaceAll(r.substring(0, r.length - 1), ""));
                      },
                      onEditingComplete: () {},
                      onSubmitted: (a) {
                        // File(ptsPath).writeAsString("\n");
                        writeToFd(Niterm.terms.first, Utf8.toUtf8("\n"));
                        // process.stdin.write("$a\n");
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        onWillPop: () async {
          return false;
        },
      ),
    );
  }
}

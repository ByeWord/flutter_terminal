import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

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
    if (Platform.isMacOS) {
      path =
          "/Users/nightmare/Library/Containers/com.nightmareTool/Data/libterm.dylib";
    }
    final dylib = DynamicLibrary.open(path);
    //等价于  char **argv;

    final getPtmIntPointer =
        dylib.lookup<NativeFunction<get_ptm_int>>('get_ptm_int');
    final GetPtmInt getPtmInt = getPtmIntPointer.asFunction<GetPtmInt>();
    int currentPtm = getPtmInt(100, 70);
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
        Utf8.toUtf8('/'),
        argv,
        envp,
        p,
        currentPtm);
    print(p.value);
    free(p);
  }

  static exec(String script) {
    var path = 'libterm.so';
    if (Platform.isMacOS) {
      path =
          "/Users/nightmare/Library/Containers/com.nightmareTool/Data/libterm.dylib";
    }
    final dylib = DynamicLibrary.open(path);
    final writetofdpointer =
        dylib.lookup<NativeFunction<write_to_fd>>('write_to_fd');
    WriteToFd writeToFd = writetofdpointer.asFunction();
    writeToFd(Niterm.terms.first, Utf8.toUtf8(script));
  }

  static getOutPut(BuildContext context, void Function(String line) callBack) {
    var path = 'libterm.so';
    if (Platform.isMacOS) {
      path =
          "/Users/nightmare/Library/Containers/com.nightmareTool/Data/libterm.dylib";
    }
    final dylib = DynamicLibrary.open(path);

    final getOutFromFdPointer =
        dylib.lookup<NativeFunction<get_output_from_fd>>('get_output_from_fd');
    GetOutFromFd getOutFromFd = getOutFromFdPointer.asFunction();
    Future.delayed(
      Duration(seconds: 1),
      () async {
        while (context.findRenderObject().attached && Niterm.terms.isNotEmpty) {
          // Utf8.fromUtf8(string)
          Pointer resultPoint = getOutFromFd(Niterm.terms.first);
          if (resultPoint.address != 0) {
            String result = Utf8.fromUtf8(resultPoint);
            if (result.startsWith("\b")) {
            } else if (result.codeUnitAt(0) == 7) {
            } else {
              // if(result)
              callBack(result);
            }
            // print(out);
          }
          free(resultPoint);
          await Future.delayed(Duration(microseconds: 0));
        }
      },
    );
  }

  @override
  _NitermState createState() => _NitermState();
}

class _NitermState extends State<Niterm> {
  bool isUseCtrl = false;
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
    if (Platform.isMacOS) {
      path =
          "/Users/nightmare/Library/Containers/com.nightmareTool/Data/libterm.dylib";
    }
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
    Future.delayed(Duration(seconds: 1), () async {
      while (mounted && Niterm.terms.isNotEmpty) {
        // Utf8.fromUtf8(string)
        Pointer resultPoint = getOutFromFd(Niterm.terms.first);
        if (resultPoint.address != 0) {
          String result = Utf8.fromUtf8(resultPoint);
          if (result.contains(String.fromCharCodes([8, 32, 8]))) {
            out = out.substring(0, out.length - 1);
            setState(() {});
          } else if (result.codeUnitAt(0) == 7) {
            print("别删了");
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
            if (mounted) {
              setState(() {});
              scrollController
                  .jumpTo(scrollController.position.maxScrollExtent);
              Future.delayed(Duration(milliseconds: 300), () {
                scrollController
                    .jumpTo(scrollController.position.maxScrollExtent);
              });
            }
          }
          // print(out);
        }
        free(resultPoint);
        await Future.delayed(Duration(microseconds: 0));
      }
      out = "";
    });
  }

  @override
  void dispose() {
    print("Niterm被销毁");
    super.dispose();
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
    // print("".codeUnits);
    // print("\b".codeUnits);
    // print("\c".codeUnits);
    listSpan = [];
    // print("${this.hashCode}out=====>$out");
    // File("/sdcard/MToolkit/out.txt").writeAsStringSync(out);
    for (String a in out.split(String.fromCharCodes([27, 91]))) {
      if (a.startsWith(RegExp("[0-9]*;"))) {
        RegExp regExp = RegExp("[0-9]*;[0-9]*m");
        String header = regExp.firstMatch(a).group(0);
        String colorNumber = header.split(";")[1];
        if (colorNumber == "34m")
          listSpan.add(
            TextSpan(
              text: a.replaceAll(header, ""),
              style: TextStyle(color: Colors.lightBlue),
            ),
          );
        else if (colorNumber == "32m")
          listSpan.add(
            TextSpan(
              text: a.replaceAll(header, ""),
              style: TextStyle(color: Colors.lightGreenAccent),
            ),
          );
        else if (colorNumber == "36m")
          listSpan.add(
            TextSpan(
              text: a.replaceAll(header, ""),
              style: TextStyle(color: Colors.greenAccent),
            ),
          );
        else if (colorNumber == "0m")
          listSpan.add(
            TextSpan(
              text: a.replaceAll(header, ""),
              style: TextStyle(color: Colors.white),
            ),
          );
      } else {
        listSpan.add(TextSpan(
            text: a.replaceAll(RegExp("^[0-9]*m"), ""),
            style: TextStyle(color: Colors.white)));
      }
    }
    return MaterialApp(
      home: WillPopScope(
        child: Scaffold(
          resizeToAvoidBottomPadding: true,
          backgroundColor: Colors.black,
          // backgroundColor: Color(0xff073542),
          body: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              buildSafeArea(context),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            writeToFd(Niterm.terms.first,
                                Utf8.toUtf8(String.fromCharCode(3)));
                          },
                          child: SizedBox(
                            height: 30,
                            width: 60.0,
                            child: Center(
                              child: Text(
                                "ESC",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            isUseCtrl = !isUseCtrl;
                            setState(() {});
                            // writeToFd(Niterm.terms.first,
                            //     Utf8.toUtf8(String.fromCharCode(3)));
                          },
                          child: SizedBox(
                            height: 30,
                            width: 60.0,
                            child: Center(
                              child: Text(
                                "CTRL",
                                style: TextStyle(
                                    color: isUseCtrl
                                        ? Colors.blueAccent
                                        : Colors.white),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            writeToFd(Niterm.terms.first,
                                Utf8.toUtf8(String.fromCharCode(3)));
                          },
                          child: SizedBox(
                            height: 30,
                            width: 60.0,
                            child: Center(
                              child: Text(
                                "ALT",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            writeToFd(Niterm.terms.first,
                                Utf8.toUtf8(String.fromCharCode(3)));
                          },
                          child: SizedBox(
                            height: 30,
                            width: 60.0,
                            child: Center(
                              child: Text(
                                "-",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        onWillPop: () async {
          return true;
        },
      ),
    );
  }

  SafeArea buildSafeArea(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () async {
          focusNode.unfocus();
          FocusScope.of(context).requestFocus(focusNode);
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        },
        onLongPress: () {},
        onLongPressEnd: (details) {
          Feedback.forLongPress(context);
          OverlayEntry overlayEntry;
          overlayEntry = OverlayEntry(
            builder: (context) {
              //外层使用Positioned进行定位，控制在Overlay中的位置
              return Positioned(
                top: details.globalPosition.dy,
                left: details.globalPosition.dx - 60,
                child: Center(
                  child: Material(
                    color: Colors.white,
                    shadowColor: Colors.grey.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                    elevation: 12.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                      child: FlatButton(
                        onPressed: () async {
                          String b =
                              (await Clipboard.getData("text/plain")).text;
                          for (String a in b.split("")) {
                            writeToFd(Niterm.terms.first, Utf8.toUtf8(a));
                          }
                          overlayEntry.remove();
                        },
                        child: Text("粘贴"),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
          //往Overlay中插入插入OverlayEntry
          Overlay.of(context).insert(overlayEntry);
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: 40.0),
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
                      if (isUseCtrl) {
                        writeToFd(
                            Niterm.terms.first,
                            Utf8.toUtf8(String.fromCharCode(r
                                    .replaceAll(str, "")
                                    .toUpperCase()
                                    .codeUnits[0] -
                                64)));
                        isUseCtrl = false;
                        setState(() {});
                      } else {
                        writeToFd(Niterm.terms.first,
                            Utf8.toUtf8(r.replaceAll(str, "")));
                      }
                    } else {
                      writeToFd(Niterm.terms.first,
                          Utf8.toUtf8(String.fromCharCode(127)));
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
    );
  }
}

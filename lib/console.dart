import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Process mConsole;

typedef ConsoleCallback = Future Function();

bool isDarkMode = true;

class Console extends StatefulWidget {
  final String tag;
  final ConsoleCallback consoleCallback;
  final String autoshell;
  final Color color;
  final Widget title;
  final String deleteCmd;
  final bool usePath; //是否使用M工具箱数据目录作为Path

  const Console({
    Key key,
    this.autoshell,
    this.color,
    this.title,
    this.tag,
    this.deleteCmd,
    this.consoleCallback,
    this.usePath,
  }) : super(key: key);

  @override
  _ConsoleState createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  Color _color; //头部的颜色
  bool canExit = true; //终端是否能被返回（true为可返回）（当所有callback执行完成自动返回）
  TextEditingController _textEditingController =
      TextEditingController(); //终端输入框的文本控制器
  List<Widget> _list = []; //
  ScrollController _scrollController = ScrollController(); //ListView滑动控制器
  FocusNode nodeOne = FocusNode();
  String pwd = "/";
  Timer _timeTicker; //
  double _time = 0; //执行任务所花费的时间
  String _text = "";

  @override
  void initState() {
    super.initState();
    _color = widget.color;
    _color ??= Colors.transparent;
    setPwd(":~$pwd #  ");
    initConsale();
    if (widget.autoshell != null) autoshell();
  }

  initConsale() {
    Map<String, String> _path = Map();
    _path["PATH"] = "/data/data/com.nightmare/files/usr/bin";
    Process.start('sh', [], includeParentEnvironment: true, runInShell: false)
        .then(
      (Process process) {
        mConsole = process;
        if (widget.usePath == null)
          mConsole.stdin.write(
              "export PATH=/data/data/com.nightmare/files/usr/bin:\$PATH\n" +
                  "export TERM=\${TERM:-dumb}\n");
        mConsole.stdout.transform(utf8.decoder).listen(
          (data) async {
            List<String> _data = data.trimRight().split("\n");
            for (String _str in _data) {
              if (_str == "Nightmare_exit_true") {
                if (widget.consoleCallback != null) {
                  await widget.consoleCallback();
                  if (widget.deleteCmd != null) {
                    //如果传进来了删除命令
                    addDeleteWidget();
                  }
                }
                canExit = true;
                _timeTicker.cancel(); //取消计时
                setState(() {});
              } else {
                if (_str == "") {
                  _updateTextToList(_str);
                } else {
                  if (_str.contains("exitCode=")) {
                  } else if (_str.contains("pwd=")) {
                    pwd = _str.replaceAll("pwd=", "");
                    setPwd(":~$pwd #  ");
                  } else {
                    print(_str);
                    _updateTextToList("\n" + _str);
                  }
                }
              }
            }
          },
        );
        mConsole.stderr.transform(utf8.decoder).listen(
          (data) {
            print(data);
            _updateTextToList(
              "\n" +
                  data.trimRight().replaceFirst(RegExp("<stdin>\\[.*\\]:"), ""),
            );
          },
        );
      },
    );
  }

  // 当有删除文件命令传进来的时候会用到
  //会在ListView中添加一个控件来与用户交互
  addDeleteWidget() {
    _list.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "是否删除源文件",
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
          InkWell(
            onTap: () {
              mConsole.stdin.write("${widget.deleteCmd}\n");
              Navigator.of(context).pop();
            },
            child: SizedBox(
              width: 80,
              child: Center(
                child: Text(
                  "是",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: SizedBox(
              width: 80,
              child: Center(
                child: Text(
                  "否",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          )
        ],
      ),
    );
    setState(() {});
  }

  // 向ListView中添加文字
  _updateTextToList(String data) async {
    _text += data;
    setState(() {});
    if (mounted) setState(() {});
  }

  autoshell() async {
    canExit = false; //拦截返回按键
    _timeTicker = Timer.periodic(
      Duration(milliseconds: 1000),
      (timer) {
        _time = timer.tick.toDouble();
        if (_text.endsWith(".") ||
            _text.endsWith("..") ||
            _text.endsWith("...")) {
          if (_text.endsWith("..."))
            _text = _text.replaceAll(RegExp("\\.\\.\\.\$"), "");
          else if (_text.endsWith("."))
            _text = _text.replaceAll(RegExp("\\.\$"), r"..");
          else if (_text.endsWith(".."))
            _text = _text.replaceAll(RegExp("\\.\\.\$"), r"...");
        } else if (_text != "") _text += r".";
        setState(() {});
      },
    );
    Future.delayed(
      Duration(milliseconds: 100),
      () async {
        for (String line in widget.autoshell.split("\n")) {
          if (line.contains(RegExp("\\[console:.*\\]"))) {
            //如果是特定字符串需要解析
            String _exec = line.replaceAll(RegExp("\\[|\\]|console:"), "");
            mConsole.stdin.write("echo $_exec\n");
            while (!_text.contains(_exec)) {
              await Future.delayed(Duration(milliseconds: 100));
            }
          } else {
            mConsole.stdin.write("$line\n");
          }
        }
      },
    );
  }

  setPwd(String pwd) async {
    _textEditingController.text = pwd;
    Future.delayed(Duration(milliseconds: 1), () {
      _textEditingController.selection = TextSelection.fromPosition(
          TextPosition(
              affinity: TextAffinity.downstream,
              offset: _textEditingController.text.length));
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _text = _text.replaceAll(
        RegExp("\\.\\.\\.\n|\\.\\.\n|\\.\n"), "\n"); //这行���码把不是最后一行的��有的点删除
    Color fontsColor = isDarkMode ? Colors.white70 : Color(0xff4b5c76);
    return MaterialApp(
      theme: ThemeData(
        iconTheme: IconThemeData(color: fontsColor),
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(color: fontsColor),
          textTheme: TextTheme(
            title: TextStyle(
              color: fontsColor,
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
        ),
      ),
      home: Scaffold(
        resizeToAvoidBottomPadding: true,
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
            child: ConsoleAppBar(
                widget: widget,
                timeTicker: _timeTicker,
                time: _time,
                color: _color),
            preferredSize: Size.fromHeight(32.5)),
        body: scaffoldBody(context),
      ),
    );
  }

  WillPopScope scaffoldBody(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!canExit) {}
        return canExit;
      },
      child: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          nodeOne.unfocus();
          Future.delayed(Duration(milliseconds: 100), () {
            FocusScope.of(context).requestFocus(nodeOne);
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Scrollbar(
            key: widget.tag == null ? null : GlobalObjectKey(widget.tag),
            child: ListView(
              cacheExtent: 3000,
              padding: EdgeInsets.only(left: 2, bottom: 10),
              controller: _scrollController,
              children: <Widget>[
                    Text(
                      _text,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.autoshell == null)
                      Container(
                        transform: Matrix4.identity()..translate(0.0, -14.0),
                        child: TextField(
                          scrollPadding: EdgeInsets.all(0.0),
                          style: TextStyle(color: Colors.black, fontSize: 14),
                          controller: _textEditingController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hasFloatingPlaceholder: false,
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(0.0),
                          ),
                          cursorColor: Colors.grey,
                          cursorWidth: 8,
                          minLines: 1,
                          maxLines: 100,
                          focusNode: nodeOne,
                          onChanged: (r) {
                            if (!r.startsWith(":~$pwd #  ")) {
                              _textEditingController.text = ":~$pwd #  ";
                              _textEditingController = TextEditingController
                                  .fromValue(TextEditingValue(
                                      text: ":~$pwd #  ",
                                      composing: TextRange.collapsed(
                                          _textEditingController.text.length),
                                      selection: TextSelection.collapsed(
                                        offset:
                                            _textEditingController.text.length,
                                        affinity: TextAffinity.downstream,
                                      )));
                              setState(() {});
                            }
                          },
                          onSubmitted: (str) async {
                            if (_text.isEmpty)
                              _text += "$str";
                            else
                              _text += "\n$str";
                            mConsole.stdin.write(_textEditingController.text
                                    .replaceAll(":~$pwd #  ", "") +
                                "\necho exitCode=\$?&&echo pwd=`pwd`\n");
                            _textEditingController.text = "";
                            setState(() {});
                          },
                          onEditingComplete: () {
                            Future.delayed(Duration(milliseconds: 200), () {
                              nodeOne.unfocus();
                              FocusScope.of(context).requestFocus(nodeOne);
                            });
                          },
                          autofocus: false,
                        ),
                      )
                  ] +
                  _list,
            ),
          ),
        ),
      ),
    );
  }
}

class ConsoleAppBar extends StatelessWidget {
  const ConsoleAppBar({
    Key key,
    @required this.widget,
    @required Timer timeTicker,
    @required double time,
    @required Color color,
  })  : _timeTicker = timeTicker,
        _time = time,
        _color = color,
        super(key: key);

  final Console widget;
  final Timer _timeTicker;
  final double _time;
  final Color _color;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
          primaryColorBrightness:
              isDarkMode ? Brightness.dark : Brightness.light,
          brightness: Brightness.light,
          accentColorBrightness: Brightness.light,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent),
      child: AppBar(
        centerTitle: true,
        titleSpacing: 0.0,
        title: Stack(
          children: <Widget>[
            widget.title ?? SizedBox(),
          ],
        ),
        actions: <Widget>[
          Align(
              alignment: Alignment.centerLeft,
              child: widget.autoshell != null
                  ? Text(
                      _timeTicker.isActive
                          ? "(已耗时${_time.toInt()}\s)"
                          : "(总耗时${_time.toInt()}\s)",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    )
                  : SizedBox()),
        ],
        elevation: 0,
        backgroundColor: _color,
        leading: Center(
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
            height: 36,
            width: 36,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              child: Icon(
                Icons.menu,
                color: widget.autoshell == null
                    ? Theme.of(context).iconTheme.color
                    : Colors.transparent,
              ),
              onTap: () {
//                if (widget.autoshell == null)
//                  Scaffold.of(pushContext).openDrawer();
              },
            ),
          ),
        ),
      ),
    );
  }
}

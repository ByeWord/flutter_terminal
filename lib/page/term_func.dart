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

typedef get_output_from_fd = Pointer<Uint8> Function(Int32);
typedef GetOutFromFd = Pointer<Uint8> Function(int);

typedef write_to_fd = Void Function(Int32, Pointer<Utf8>);
typedef WriteToFd = void Function(int, Pointer<Utf8>);

typedef getfilepath = Pointer<Utf8> Function(Int32 fd);
typedef GetFilePathFromFdDart = Pointer<Utf8> Function(int fd);
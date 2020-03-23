import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:flutter_qiniu/entity/file_path_entity.dart';
export 'package:flutter_qiniu/entity/file_path_entity.dart';

enum QNFixedZone {
  zone0, // 华东
  zone1, // 华北
  zone2, //华南
  zoneNa0, //北美
  zoneAs0 // 新加坡
}

class FlutterQiniu {
  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_qiniu_method');

  static const EventChannel _eventChannel =
      const EventChannel('flutter_qiniu_event');

  QNFixedZone zone = QNFixedZone.zone0;

  Stream _onProgressChanged;

  Stream onProgressChanged() {
    if (_onProgressChanged == null) {
      _onProgressChanged = _eventChannel.receiveBroadcastStream();
    }
    return _onProgressChanged;
  }

  FlutterQiniu({this.zone});

  /// 单个文件上传
  ///
  /// [filePath] 文件路径
  /// [key] 保存在服务器上的资源唯一标识
  /// [token] 服务器分配的 token
  Future<Map> uploadFile(String filePath, String key, String token) async {
    Map<String, String> map = {
      "filePath": filePath,
      "key": key,
      "token": token,
      "zone": zone.index.toString()
    };

    var result = await _methodChannel.invokeMethod('uploadFile', map);
    return _processResult(result);
  }

  /// 单个文件上传
  ///
  /// [data] 数据
  /// [key] 保存在服务器上的资源唯一标识
  /// [token] 服务器分配的 token
  Future<Map> uploadData(Uint8List data, String key, String token) async {
    Map<String, dynamic> map = {
      "data": data,
      "key": key,
      "token": token,
      "zone": zone.index.toString()
    };

    var result = await _methodChannel.invokeMethod('uploadData', map);
    return _processResult(result);
  }

  Map _processResult(String result) {
    Map data;
    if (result is String) {
      try {
        var decode = jsonDecode(result);
        if (decode is Map) {
          data = decode;
        } else {
          print("unexpected decode result: $decode");
        }
      } catch (e) {
        print("decode response failed: $result");
        print(e);
      }
    } else {
      print("unexpected response data: $result");
    }
    return data;
  }

  /// 上传多个文件
  Future<List<String>> uploadFiles(List<FilePathEntity> entities) async {
    var uploads = entities.map((entity) {
      return uploadFile(entity.filePath, entity.key, entity.token);
    });

    var results = await Future.wait(uploads);
    return results;
  }
}

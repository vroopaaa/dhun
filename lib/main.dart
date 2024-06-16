import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('YouTube Song Downloader'),
        ),
        body: DownloadPage(),
      ),
    );
  }
}

class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final TextEditingController _controller = TextEditingController();
  String _message = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
      status = await Permission.storage.status;
      if (!status.isGranted) {
        setState(() {
          _message = 'Storage permission required for downloading files.';
        });
      }
    }
  }

  Future<void> _downloadSong(String url) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.13:5000/download'),  // Replace with your server's IP address
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'url': url,
        }),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final fileUrl = responseJson['file_path'];

        var status = await Permission.storage.status;
        if (status.isGranted) {
          final directory = await getExternalStorageDirectory();
          final filePath = '${directory?.path}/$fileUrl';

          final fileResponse = await http.get(Uri.parse('http://192.168.1.13:5000/$fileUrl'));
          if (fileResponse.statusCode == 200) {
            final file = File(filePath);
            await file.writeAsBytes(fileResponse.bodyBytes);

            setState(() {
              _message = 'Download successful! File saved at: $filePath';
            });
          } else {
            setState(() {
              _message = 'Error downloading file: ${fileResponse.reasonPhrase}';
            });
          }
        } else {
          setState(() {
            _message = 'Storage permission not granted. Cannot download file.';
          });
        }
      } else {
        final responseJson = jsonDecode(response.body);
        setState(() {
          _message = 'Error: ${responseJson['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter YouTube URL',
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final url = _controller.text;
              if (url.isNotEmpty) {
                _downloadSong(url);
              }
            },
            child: Text('Download'),
          ),
          SizedBox(height: 20),
          Text(_message),
        ],
      ),
    );
  }
}

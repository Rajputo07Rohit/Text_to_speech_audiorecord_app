import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:assets_audio_player/assets_audio_player.dart';

class AudioListPage extends StatefulWidget {
  final List<String> savedTexts;

  const AudioListPage({Key? key, required this.savedTexts}) : super(key: key);
  @override
  _AudioListPageState createState() => _AudioListPageState();
}

class _AudioListPageState extends State<AudioListPage> {
  final String directoryPath = '/sdcard/Download/';
  List<File> audioFiles = [];

  @override
  void initState() {
    super.initState();
    audioFiles = getAudioFiles();
  }

  List<File> getAudioFiles() {
    Directory directory = Directory(directoryPath);
    List<File> audioFiles = [];

    if (directory.existsSync()) {
      audioFiles = directory
          .listSync()
          .where((file) =>
              file is File &&
              (file.path.endsWith('.wav') ||
                  file.path.endsWith('.mp3') ||
                  file.path.endsWith('.m4a')))
          .cast<File>()
          .toList();
    }

    return audioFiles;
  }

  AssetsAudioPlayer _audioPlayer = AssetsAudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 237, 223, 223),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 91, 1, 4),
        title: const Text(
          'Audio Recorder',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: audioFiles.isEmpty
          ? Center(
              child: Text(
                'No audio files Present.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: audioFiles.length,
              itemBuilder: (context, index) {
                String fileName = path.basename(audioFiles[index].path);
                return Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      fileName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // leading: Icon(Icons.music_note),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () {
                            _audioPlayer.open(
                              Audio.file(audioFiles[index].path),
                              autoStart: true,
                              showNotification: true,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.stop),
                          onPressed: () {
                            _audioPlayer.stop();
                            print(widget.savedTexts);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            File audioFile = audioFiles[index];
                            audioFile.deleteSync();
                            setState(() {
                              audioFiles.removeAt(index);
                            });
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            // Handle the "Pop on Writer Transcript" action here
                            if (value == 'pop_transcript') {
                              // Add your code to pop the transcript
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem<String>(
                                value: 'pop_transcript',
                                child: Text('Change to text'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

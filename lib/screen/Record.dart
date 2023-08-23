import 'dart:async';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firep/screen/audio_list_page.dart';
import 'package:firep/screen/speech_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:google_speech/google_speech.dart';

class MyHomePage extends StatefulWidget {
  final List<String> savedTexts;

  const MyHomePage({Key? key, required this.title, required this.savedTexts})
      : super(key: key);
  // const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FlutterSoundRecorder _recordingSession;
  final recordingPlayer = AssetsAudioPlayer();
  late String pathToAudio;
  bool playAudio = false;
  bool isRecording = false;
  String successMessage = '';
  bool isSpeechToTextMode = true;

  Timer? _recordTimer;
  int _recordDuration = 0; // in seconds

  late TextEditingController fileNameController;

  @override
  void initState() {
    super.initState();
    initializer();
  }

  void initializer() async {
    pathToAudio = '/sdcard/Download/temp.wav';

    _recordingSession = FlutterSoundRecorder();

    await _recordingSession.openRecorder();
    await _recordingSession
        .setSubscriptionDuration(const Duration(milliseconds: 10));
    await initializeDateFormatting();
    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> startRecording() async {
    Directory directory = Directory(path.dirname(pathToAudio));

    if (!directory.existsSync()) {
      directory.createSync();
    }

    _recordingSession.openRecorder();

    await _recordingSession.startRecorder(
      toFile: pathToAudio,
      codec: Codec.pcm16WAV,
    );

    setState(() {
      isRecording = true;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration++;
        });
      });
    });
  }

  Future<String?> stopRecording() async {
    setState(() {
      isRecording = false;
      _recordTimer?.cancel();
      _recordDuration = 0;
    });

    _recordingSession.closeRecorder();

    return await _recordingSession.stopRecorder();
  }

  Future<void> playFunc() async {
    recordingPlayer.open(
      Audio.file(pathToAudio),
      autoStart: true,
      showNotification: true,
    );

    setState(() {
      playAudio = true;
    });
  }

  Future<void> stopPlayFunc() async {
    setState(() {
      playAudio = false;
    });

    recordingPlayer.stop();
  }

  String getRecordingButtonText() {
    return isRecording ? "Stop" : "Record";
  }

  bool recognizing = false;
  bool recognizeFinished = false;
  String text = 'Hold the button and start speaking';

  void transcribe(String fullpath) async {
    setState(() {
      recognizing = true;
    });
    final serviceAccount = ServiceAccount.fromString(
        (await rootBundle.loadString('assets/speechtext09-9b58916abcbd.json')));
    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);
    final config = _getConfig();
    final audio = await _getAudioContent(fullpath);

    await speechToText.recognize(config, audio).then((value) {
      setState(() {
        text = value.results
            .map((e) => e.alternatives.first.transcript)
            .join('\n');
      });
    }).whenComplete(() => setState(() {
          recognizeFinished = true;
          recognizing = false;
        }));
  }

  RecognitionConfig _getConfig() => RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: true,
      sampleRateHertz: 16000,
      languageCode: 'en-US');

  Future<List<int>> _getAudioContent(String path) async {
    return File(path).readAsBytesSync().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 237, 223, 223),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.file_open,
            color: Colors.white,
            size: 38,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AudioListPage(savedTexts: widget.savedTexts),
              ),
            );
          },
        ),
        backgroundColor: const Color.fromARGB(255, 91, 1, 4),
        centerTitle: true,
        elevation: 0.0,
        title: const Text(
          "Audio Recording",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Row(
              children: [
                Text(
                  'Speech-to-Text',
                  style: TextStyle(
                    color: !isSpeechToTextMode
                        ? Color.fromARGB(255, 239, 137, 137)
                        : Colors.white,
                  ),
                ),
                Switch(
                  value: isSpeechToTextMode,
                  onChanged: (value) {
                    setState(() {
                      isSpeechToTextMode = value;
                    });

                    // Navigate to the desired page when the switch is slid
                    if (!isSpeechToTextMode) {
                      // Navigate to Speech-to-Text screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SpeechScreen(savedTexts: widget.savedTexts)),
                      );
                    } else {
                      // Navigate to Audio Recording screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyHomePage(
                                title: 'Record Audio',
                                savedTexts: widget.savedTexts)),
                      );
                    }
                  },
                  activeTrackColor: Colors.white,
                  activeColor: Colors.white,
                ),
                Text(
                  'Audio Recording',
                  style: TextStyle(
                    color: !isSpeechToTextMode
                        ? Colors.white
                        : Color.fromARGB(255, 226, 124, 117),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  child: ElevatedButton(
                    // onPressed: isRecording ? stopRecording : startRecording,
                    onPressed: () async {
                      if (isRecording) {
                        stopRecording();

                        transcribe(pathToAudio);
                      } else {
                        await startRecording();
                      }
                    },

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mic,
                          size: 20,
                          color: Colors.white,
                        ),
                        // const SizedBox(width: 8),
                        Text(
                          getRecordingButtonText(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(40, 40),
                      backgroundColor: Color.fromARGB(255, 123, 6, 6),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(60), // Make it a circle
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: playAudio ? stopPlayFunc : playFunc,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          playAudio ? Icons.stop : Icons.play_arrow,
                          size: 20,
                          color: Colors.white,
                        ),
                        // const SizedBox(width: 20),
                        Text(
                          playAudio ? "Stop" : "Play",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(40, 40),
                      backgroundColor: Color.fromARGB(255, 123, 6, 6),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(60), // Make it a circle
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      saveRecordingToDevice();
                      if (text.trim().isNotEmpty) {
                        widget.savedTexts.add(text);
                        text = " ";
                      }
                      print(widget.savedTexts);
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(40, 40),
                      backgroundColor: Color.fromARGB(255, 123, 6, 6),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(60), // Make it a circle
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding:
                  EdgeInsets.only(bottom: 20), // Add padding to create space
              child: Text(
                'Duration: $_recordDuration seconds',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              text.isNotEmpty ? text : "Hold the button and start speaking",
              style: TextStyle(
                fontSize: 16,
                color: isListening ? Colors.black87 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Text(text),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                successMessage,
                style: TextStyle(
                  color: successMessage == 'File saved successfully'
                      ? Colors.red
                      : Colors.green,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showFileNameDialog() async {
    TextEditingController fileNameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Save Audio"),
          content: TextField(
            controller: fileNameController,
            decoration: InputDecoration(labelText: "Enter File Name"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(fileNameController.text);
              },
              child: Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveRecordingToDevice() async {
    String destinationFolder = '/sdcard/Download/';
    String? customFileName = await _showFileNameDialog();

    if (customFileName != null && customFileName.isNotEmpty) {
      String destinationPath =
          path.join(destinationFolder, '$customFileName.wav');
      File sourceFile = File(pathToAudio);
      File destinationFile = File(destinationPath);

      try {
        if (!destinationFile.existsSync()) {
          await destinationFile.create(recursive: true);
        }

        await sourceFile.copy(destinationPath);

        setState(() {
          successMessage = 'File saved successfully!';
        });

        // Clear the success message after a delay
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            successMessage = '';
          });
        });
      } catch (error) {
        setState(() {
          successMessage = 'Error saving the file.';
        });
      }
    }
  }
}

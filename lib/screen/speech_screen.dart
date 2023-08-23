import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'Record.dart';
import 'saved_text_screen.dart';
import '../color.dart/colors.dart';
import 'dart:convert';

class SpeechScreen extends StatefulWidget {
  final List<String> savedTexts;

  const SpeechScreen({Key? key, required this.savedTexts}) : super(key: key);
  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

SpeechToText speechToText = SpeechToText();

var text = ""; // Initialize with an empty string
var isListening = false;

class _SpeechScreenState extends State<SpeechScreen> {
  // List<String> savedTexts = [];
  final String fabRefreshTag = 'fabRefresh';
  final String fabSaveTag = 'fabSave';
  bool isSpeechToTextMode =
      false; // Track the mode, true for speech-to-text, false for audio recording

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
                    SavedTextScreen(savedTexts: widget.savedTexts),
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 91, 1, 4),
        elevation: 0.0,
        title: const Text(
          "Speech to Text",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          // Add the slider to the AppBar
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Row(
              children: [
                Text(
                  'Speech-to-Text',
                  style: TextStyle(
                    color: !isSpeechToTextMode
                        ? Color.fromARGB(255, 255, 160, 153)
                        : Colors.white,
                  ),
                ),
                // Text('Speech-to-Text'),
                Switch(
                  value: isSpeechToTextMode,
                  onChanged: (value) {
                    setState(() {
                      isSpeechToTextMode = value;
                    });

                    // Navigate to the desired page when the switch is slid
                    if (!isSpeechToTextMode) {
                      // isSpeechToTextMode = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              // SavedTextScreen(savedTexts: savedTexts)
                              MyHomePage(
                                  title: 'Record Audio',
                                  savedTexts: widget.savedTexts),
                        ),
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
      body: SingleChildScrollView(
        reverse: true,
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          margin: const EdgeInsets.only(bottom: 150),
          child: Text(
            text.isNotEmpty ? text : "Hold the button and start speaking",
            style: TextStyle(
              fontSize: 20,
              color: isListening ? Colors.black87 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            heroTag: fabRefreshTag,
            onPressed: () {
              setState(() {
                text = ""; // Reset the text to an empty string
              });
            },
            child: const CircleAvatar(
              backgroundColor: Color.fromARGB(255, 123, 6, 6),
              radius: 35,
              child: Icon(
                Icons.refresh,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          AvatarGlow(
            endRadius: 75.0,
            animate: isListening,
            duration: const Duration(milliseconds: 2000),
            glowColor: Colors.red,
            repeat: true,
            repeatPauseDuration: const Duration(milliseconds: 500),
            showTwoGlows: true,
            child: GestureDetector(
              onTapDown: (_) async {
                if (!isListening) {
                  var available = await speechToText.initialize();
                  if (available) {
                    setState(() {
                      isListening = true;
                    });
                    speechToText.listen(
                      onResult: (result) {
                        if (text == "Hold the button and start speaking") {
                          text = '';
                        } else {
                          if (result.finalResult) {
                            setState(() {
                              text = '$text ${result.recognizedWords}';
                            });
                          }
                        }
                      },
                      cancelOnError: false, // Keep listening even on error
                    );
                  }
                }
              },
              onTapUp: (_) {
                setState(() {
                  isListening = false;
                });
                speechToText.stop();
              },
              child: CircleAvatar(
                backgroundColor: isListening
                    ? Colors.green
                    : Color.fromARGB(194, 176, 16, 16),
                radius: 35,
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: fabSaveTag,
            onPressed: () {
              if (text.trim().isEmpty) {
                // Show a popup if the text is empty
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Error'),
                      content: const Text(
                          'The text is empty. Please speak and try again.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                // Save the non-empty text
                setState(() {
                  widget.savedTexts.add(text);
                });

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Text Saved'),
                      content:
                          const Text('The text has been successfully saved.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: const CircleAvatar(
              backgroundColor: Color.fromARGB(255, 123, 6, 6),
              radius: 35,
              child: Icon(
                Icons.save,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as soun;

import '../color.dart/colors.dart';

class SavedTextScreen extends StatefulWidget {
  final List<String> savedTexts;

  const SavedTextScreen({Key? key, required this.savedTexts}) : super(key: key);

  @override
  _SavedTextScreenState createState() => _SavedTextScreenState();
}

class _SavedTextScreenState extends State<SavedTextScreen> {
  TextEditingController _editingController = TextEditingController();
  int _editingIndex = -1;
  soun.SpeechToText _speech = soun.SpeechToText();
  TextEditingController names = TextEditingController();

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
  }

  // dialog showing

  Future<String?> displayFileNameDialog(BuildContext context) async {
    final fileNameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter File Name'),
          content: TextFormField(
            controller: fileNameController,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'File Name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(fileNameController.text);
              },
            ),
          ],
        );
      },
    );
  }

//  download list file

  void _downloadListToFile(List<String> strings) async {
    try {
      PermissionStatus permissionStatus = await Permission.storage.status;
      if (!permissionStatus.isGranted) {
        PermissionStatus newPermissionStatus =
            await Permission.storage.request();
        if (!newPermissionStatus.isGranted) {
          return;
        }
      }

      String? directory = await FilePicker.platform.getDirectoryPath();
      String? fileName;
      String filePath;

      do {
        fileName = await displayFileNameDialog(context);
        if (fileName == null || fileName.isEmpty) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('No filename provided. Note was not saved.'),
              backgroundColor: Colors.red, // Red color for failure
            ),
          );
          return;
        }
        filePath = '$directory/$fileName.txt';
        final file = File(filePath);
        if (file.existsSync()) {
          // ignore: use_build_context_synchronously
          FileConflictResult conflictResult = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('File Already Exists'),
                content: const Text(
                  'A file with the same name already exists. Do you want to change the file name again?',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Change Name'),
                    onPressed: () {
                      Navigator.of(context).pop(FileConflictResult.changeName);
                    },
                  ),
                  TextButton(
                    child: const Text('Replace'),
                    onPressed: () {
                      Navigator.of(context).pop(FileConflictResult.replace);
                    },
                  ),
                ],
              );
            },
          );

          if (conflictResult == FileConflictResult.replace) {
            // Replace the existing file with the new one
            break;
          }
        } else {
          break;
        }
      } while (true);

      String contents = strings.join("\n");
      final file = File(filePath);
      await file.writeAsString(contents);

      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('List of texts saved successfully as: $fileName'),
          backgroundColor: Colors.green, // Green color for success
        ),
      );
    } catch (e) {
      print(e);
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Failed to save list of texts.'),
          backgroundColor: Colors.red, // Red color for failure
        ),
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text(
              ' Check app permission --> storage --> Allow management of all files is selected. '),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

//  downlaod single file
  void _downloadIndividualFile(String notes) async {
    try {
      PermissionStatus permissionStatus = await Permission.storage.status;
      if (!permissionStatus.isGranted) {
        PermissionStatus newPermissionStatus =
            await Permission.storage.request();
        if (!newPermissionStatus.isGranted) {
          return;
        }
      }
      String? directory = await FilePicker.platform.getDirectoryPath();
      String? fileName;
      String filePath;

      do {
        // ignore: use_build_context_synchronously
        fileName = await displayFileNameDialog(context);
        if (fileName == null || fileName.isEmpty) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('No filename provided. Note was not saved.'),
              backgroundColor: Colors.red, // Red color for failure
            ),
          );
          return;
        }
        filePath = '$directory/$fileName.txt';
        final file = File(filePath);
        if (file.existsSync()) {
          // ignore: use_build_context_synchronously
          FileConflictResult conflictResult = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('File Already Exists'),
                content: const Text(
                  'A file with the same name already exists. Do you want to change the file name again?',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Change Name'),
                    onPressed: () {
                      Navigator.of(context).pop(FileConflictResult.changeName);
                    },
                  ),
                  TextButton(
                    child: const Text('Replace'),
                    onPressed: () {
                      Navigator.of(context).pop(FileConflictResult.replace);
                    },
                  ),
                ],
              );
            },
          );

          if (conflictResult == FileConflictResult.replace) {
            // Replace the existing file with the new one
            break;
          }
        } else {
          break;
        }
      } while (true);

      final file = File(filePath);
      await file.writeAsString(notes);

      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Note saved successfully under the name: $fileName'),
          backgroundColor: Colors.green, // Green color for success
        ),
      );
    } catch (e) {
      // print(e);
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Failed to save note.'),
          backgroundColor: Colors.red, // Red color for failure
        ),
      );
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text(
              ' Check app permission --> storage --> Allow management of all files is selected. '),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTextPresent = widget.savedTexts.isNotEmpty;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 237, 223, 223),
        appBar: AppBar(
          title: const Text('Saved Texts'),
          backgroundColor: const Color.fromARGB(
              255, 91, 1, 4), // Update the background color
        ),
        body: Column(
          children: [
            Expanded(
              child: isTextPresent
                  ? ListView.builder(
                      itemCount: widget.savedTexts.length,
                      itemBuilder: (context, index) {
                        final text = widget.savedTexts[index];
                        return Container(
                          color: Colors.black,
                          child: Card(
                            elevation: 3,
                            child: ListTile(
                              title: _editingIndex == index
                                  ? TextField(
                                      controller: _editingController,
                                      onChanged: (value) {
                                        setState(() {
                                          widget.savedTexts[index] = value;
                                        });
                                      },
                                      onSubmitted: (value) {
                                        setState(() {
                                          _editingIndex = -1;
                                        });
                                      },
                                    )
                                  : Text(text),
                              trailing: _editingIndex == index
                                  ? IconButton(
                                      icon: Icon(Icons.check),
                                      onPressed: () {
                                        var popo =
                                            _editingController.text.toString();
                                        if (popo.trim().isNotEmpty) {
                                          setState(() {
                                            _editingIndex = -1;
                                            widget.savedTexts[index] = popo;
                                            _editingController.clear();
                                          });
                                        } else {
                                          _editingController.clear();
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: Text("WARNING"),
                                                  content:
                                                      Text("TEXT IS EMPTY"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: Text("ok"))
                                                  ],
                                                );
                                              });
                                        }
                                      },
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            setState(() {
                                              _editingIndex = index;
                                              _editingController.text = text;
                                              _listenForSpeech();
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Delete Text'),
                                                  content: Text(
                                                      'Are you sure you want to delete this text?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        _deleteText(index);
                                                      },
                                                      child: Text('Delete'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.copy),
                                          onPressed: () {
                                            Clipboard.setData(
                                                ClipboardData(text: text));
                                            _scaffoldMessengerKey.currentState
                                                ?.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Text copied to clipboard'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.download),
                                          onPressed: () {
                                            _downloadIndividualFile(text);
                                          },
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No text is present!',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            Visibility(
              visible: isTextPresent,
              child: ElevatedButton(
                onPressed: () {
                  _downloadListToFile(widget.savedTexts);
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.red,
                  onPrimary: Colors.white,
                ),
                child: Text('Download All Text'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteText(int index) {
    setState(() {
      if (index >= 0 && index < widget.savedTexts.length) {
        widget.savedTexts.removeAt(index);
      }
    });
  }

  void _listenForSpeech() async {
    bool available = await _speech.initialize(
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      print('Speech recognition available.');
      _speech.listen(
        onResult: (result) {
          setState(() {
            print('Speech recognized: ${result.recognizedWords}');
            _editingController.text = result.recognizedWords;
          });
        },
      );
    } else {
      print('Speech recognition not available on this device.');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content:
              const Text('Speech recognition not available on this device.'),
          backgroundColor: Colors.red, // Red color for failure
        ),
      );
    }
  }
}

enum FileConflictResult {
  changeName,
  replace,
}

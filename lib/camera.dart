// Import statements for necessary packages and dependencies
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:meallens_app/menueprovider.dart';
import 'package:provider/provider.dart';

// Define a StatefulWidget for the CameraPage
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

// Define the State class for the CameraPage
class _CameraPageState extends State<CameraPage> {
  // Declare necessary variables and controllers
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  XFile? imageFile;
  Map<String, dynamic> groceries = {};
  List<String?> selectedOptions = [];
  String? selectedIngredient; // Define the selected value
  late MenueProvider _menueProvider;
  late double _threshhold = 0.5;
  Future<void>? _initializeControllerFuture;

  // Initialize necessary resources and controllers
  @override
  void initState() {
    super.initState();
    _menueProvider = Provider.of<MenueProvider>(context, listen: false);
    // Store the Future returned by startCamera
    _initializeControllerFuture = startCamera();
  }

  // Dispose of resources when the State is disposed
  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // Camera Methods
  // Method to start the camera
  Future<void> startCamera() async {
    cameras = await availableCameras();
    var backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras[0],
    );

    cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await cameraController.initialize();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    // Return the initialization Future
    return cameraController.initialize();
  }

  // Image Upload Method
  // Method to upload captured image for analysis
  Future<void> uploadImage() async {
    var uri = Uri.parse('https://api.mircofost.com/detect');
    var request = http.MultipartRequest('POST', uri);

    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile!.path));
    request.fields['threshold'] = _threshhold.toString();

    if (kDebugMode) {
      print(request.fields);
      print(request.files);
    }

    var response = await request.send();
    var responseData = await response.stream.transform(utf8.decoder).first;
    var decodedResponse = json.decode(responseData);

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("Uploaded!");
      }
      if (kDebugMode) {
        print(decodedResponse);
      }
      setState(() {
        groceries = decodedResponse;
        // Trigger a rebuild of the widget tree
      });
    } else {
      if (kDebugMode) {
        print("Failed to upload.");
      }
      throw Exception('Failed to upload image');
    }
  }

  // Method to fetch ingredients from API
  Future<List<String>> fetchIngredients() async {
    final response = await http.get(Uri.parse('https://api.mircofost.com/ingredients'));

    if (response.statusCode == 200) {
      final parsed = json.decode(response.body);
      if (parsed is Map && parsed.containsKey('data')) {
        final data = parsed['data'];
        if (data is List) {
          List<String> ingredients = data.map<String>((json) => json['Name'] as String).toList();
          // Sort the ingredients alphabetically
          ingredients.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          return ingredients;
        }
      }
      throw Exception('Unexpected JSON structure');
    } else {
      throw Exception('Failed to load ingredients');
    }
  }

  // Method to fetch meat types from API
  Future<List<String>> fetchMeat() async {
    final response =
    await http.get(Uri.parse('https://api.mircofost.com/ingredients/meat'));

    if (response.statusCode == 200) {
      final parsed = json.decode(response.body);
      if (parsed is Map && parsed.containsKey('data')) {
        final data = parsed['data'];
        if (data is List) {
          return data.map<String>((json) => json['Name'] as String).toList();
        }
      }
      throw Exception('Unexpected JSON structure');
    } else {
      throw Exception('Failed to load ingredients');
    }
  }

  // Widget Building Methods
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the camera preview.
          return groceries.isNotEmpty ? buildListView() : buildCameraPreview();
        } else {
          // Otherwise, display a loading indicator.
          return Center(
              child: Lottie.asset(
                'assets/loadingIndicator.json',
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.5,
              ));
        }
      },
    );
  }

  // Widget for Camera Preview
  Widget buildCameraPreview() {
    return Scaffold(
      // Scaffold body with camera preview and related UI elements
      body: Stack(
        children: [
          // Camera preview widget
          Positioned.fill(
            child: CameraPreview(cameraController),
          ),
          // Image display if available
          if (imageFile != null)
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Image.file(
                  File(imageFile!.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Close button for displayed image
          if (imageFile != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    onPressed: () {
                      setState(() {
                        imageFile = null; // Reset the imageFile to null
                      });
                    },
                  ),
                ),
              ),
            ),
          // Info button to display instructions
          Align(
            alignment: Alignment.bottomLeft,
            child: IconButton(
              icon: const Icon(Icons.info, size: 30),
              color: Colors.white,
              padding: const EdgeInsets.only(
                  left: 40.0, top: 20.0, right: 10.0, bottom: 30.0),
              onPressed: () {
                // Show dialog with instructions
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Anleitung',
                          style: TextStyle(
                              fontSize: 20.0,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFA4C787))),
                      content: const SingleChildScrollView(
                        child: ListBody(
                          children: <Widget>[
                            Text('1. Erlaube Kamerazugriff',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w400,
                                )),
                            Text('2. Fotografiere Lebensmittel',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w400,
                                )),
                            Text('3. Bestätige für KI-Analyse',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w400,
                                )),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Zum Tutorial ...',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFA4C787),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFA4C787),
                                decorationThickness: 2,
                              )),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _menueProvider.setSelectedIndex(0);
                            _menueProvider.pageController.animateToPage(
                              _menueProvider.selectedIndex,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.linear,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Sensitivity slider
          Align(
              alignment: Alignment.bottomCenter,
              child:
              Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (imageFile != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0), // adjust border radius as needed
                    ),
                    padding: const EdgeInsets.all(8.0), // adjust padding as needed
                    margin: const EdgeInsets.symmetric(horizontal: 30.0), // adjust margin as needed
                    child: const Text(
                      'Erkennungs-Sensibilität',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFA4C787),
                      ),
                    ),
                  ),
                if (imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 30.0, top: 2.0, right: 30.0, bottom: 10.0),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFA4C787),
                          inactiveTrackColor: Colors.white.withOpacity(0.8),
                          thumbColor: const Color(0xFFA4C787),
                          overlayColor:
                          const Color(0xFFA4C787).withOpacity(0.2),
                          valueIndicatorColor: const Color(0xFFA4C787)),
                      child: Slider(
                        value: _threshhold,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '$_threshhold',
                        onChanged: (double value) {
                          setState(() {
                            _threshhold = value;
                          });
                        },
                      ),
                    ),
                  ),
                GestureDetector(
                    onTap: () {
                      cameraController.takePicture().then((XFile? file) {
                        if (mounted) {
                          if (file != null) {
                            if (kDebugMode) {
                              print("Picture saved to ${file.path}");
                            }

                            // Turn off the flash after capturing the image
                            cameraController.setFlashMode(FlashMode.off);

                            setState(() {
                              imageFile = file; // Store the image file
                            });
                          }
                        }
                      });
                    },
                    child: Opacity(
                      opacity: 0.8,
                      child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(2, 2),
                                blurRadius: 10,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 7.0,
                            ),
                          )),
                    )),
              ])),
          // Submit button
          if (imageFile != null)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, top: 20.0, right: 20.0, bottom: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    uploadImage();
                  },
                  child: const Text(
                    'Absenden',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w800,
                      height: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget for displaying detected groceries
  Widget buildListView() {
    for (int i = 0; i < groceries['data'].length; i++) {
      selectedOptions.add(null);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detected Groceries'),
      ), //AppBar
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 60, left: 10, right: 10),
            child: ListView.builder(
              itemCount: groceries['data'].length + 1,
              itemBuilder: (context, index) {
                if (index < groceries['data'].length) {
                  var grocery = groceries['data'][index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(15), // Added rounded corners
                    ),
                    color: Colors.lightGreen[100],
                    // Adjusted color to match image style
                    child: ListTile(
                      title: Text(
                        grocery['Name'],
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w400,
                          height: 0,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel_rounded,
                            color: Colors.black87),
                        // Changed icon color to black
                        onPressed: () {
                          setState(() {
                            groceries['data'].removeAt(index);
                            selectedOptions.removeAt(index);
                          });
                        },
                      ),
                      subtitle: grocery['Name'] == 'Fleisch'
                          ? FutureBuilder<List<String>>(
                        future: fetchMeat(),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<String>> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center();
                          } else if (snapshot.hasError) {
                            if (kDebugMode) {
                              print('Error: ${snapshot.error}');
                            }
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                         'Fleischart auswählen',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                PopupMenuButton<String>(
                                  offset: const Offset(0, 20),
                                  itemBuilder: (BuildContext context) {
                                    return snapshot.data!.map((String value) {
                                      return PopupMenuItem<String>(
                                        value: value,
                                        child: SizedBox(
                                          height: 25,
                                          child: Text(value),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  onSelected: (String newValue) {
                                    setState(() {
                                      // Update the groceries map with the selected meat type
                                      groceries['data'][index]['Name'] =
                                          newValue;

                                      selectedOptions[index] = newValue;
                                      if (kDebugMode) {
                                        print(
                                            'Selected option at index $index: $newValue');
                                      }
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down),
                                ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      )
                          : null,
                    ),
                  );
                } else {
                  return FutureBuilder<List<String>>(
                    future: fetchIngredients(), // Your future method here
                    builder: (BuildContext context,
                        AsyncSnapshot<List<String>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Show a loading indicator while waiting for the data
                        return const Center();
                      } else if (snapshot.hasError) {
                        if (kDebugMode) {
                          print('Error: ${snapshot.error}');
                        }
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Card(
                          child: GestureDetector(
                            onTap: () {
                              // Open the PopupMenuButton when the ListTile is tapped
                              showMenu<String>(
                                context: context,
                                position: const RelativeRect.fromLTRB(10, 0, 0, 0),
                                items: snapshot.data!.map((String value) {
                                  return PopupMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ).then((String? newValue) {
                                // Handle the selection if an item is selected
                                if (newValue != null) {
                                  setState(() {
                                    groceries['data'].add({"Name": newValue});
                                    selectedOptions.add(null);
                                  });
                                }
                              });
                            },
                            child: const ListTile(
                              title: Text(
                                'Lebensmittel hinzufügen',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w800,
                                  height: 0,
                                ),
                              ),
                              trailing: Icon(Icons.add_circle),
                            ),
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: () async {
                    if (kDebugMode) {
                      print('button pressed');
                    }
                    List ingredients = groceries['data'].map((grocery) {
                      return {"Name": grocery['Name']};
                    }).toList();

                    List<String> stringIngredients = ingredients
                        .map((item) => item['Name'] as String)
                        .toList();

                    _menueProvider.setStringIngredients(stringIngredients);

                    _menueProvider.setSelectedIndex(2);
                    _menueProvider.pageController.animateToPage(
                      _menueProvider.selectedIndex,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.linear,
                    );
                  },
                  child: const Text('Rezepte finden'),
                ),
              )),
        ],
      ),
    );
  }
}

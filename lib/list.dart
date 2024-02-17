import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'detailpage.dart';
import 'menueprovider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipeList extends StatefulWidget {
  const RecipeList({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RecipeListState createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  late Future<List> loadedRecepies;
  late List ingredients;
  late MenueProvider _menueProvider;
  List _filteredRecipes = [];
  bool _showFilterOptions = false;
  late Map<String, dynamic> allergens;
  late Map<String, dynamic> devices;
  late Map<String, dynamic> labels;
  late Map<String, dynamic> nutrients;
  final Map<String, bool> _allergensToggleStates = {};
  final Map<String, bool> _devicesToggleStates = {};
  final Map<String, bool> _labelsToggleStates = {};
  final Map<String, bool> _nutrientsToggleStates = {};

  @override
  void initState() {
    super.initState();
    _menueProvider = Provider.of<MenueProvider>(context, listen: false);

    // Load recipes based on menu provider ingredients or all recipes if no ingredients specified
    if (_menueProvider.stringIngredients.isNotEmpty) {
      loadedRecepies = fetchRecipes(_menueProvider.stringIngredients);
      _menueProvider.setStringIngredients([]);
    } else {
      loadedRecepies = fetchAllRecipes();
    }

    // Fetch filter options for allergens, devices, labels, and nutrients
    Future.wait([
      fetchFilterOptions('Allergens'),
      fetchFilterOptions('Devices'),
      fetchFilterOptions('Labels'),
      fetchFilterOptions('Nutrients'),
    ]).then((List<dynamic> optionsList) {
      setState(() {
        allergens = optionsList[0] as Map<String, dynamic>;
        devices = optionsList[1] as Map<String, dynamic>;
        labels = optionsList[2] as Map<String, dynamic>;
        nutrients = optionsList[3] as Map<String, dynamic>;

        // Initialize toggle states for each category
        initializeToggleStates(
            'Allergen', allergens['data'], _allergensToggleStates);
        initializeToggleStates('Device', devices['data'], _devicesToggleStates);
        initializeToggleStates('Label', labels['data'], _labelsToggleStates);
        initializeToggleStates(
            'Nutrient', nutrients['data'], _nutrientsToggleStates);
      });
    });
  }

  // Method to fetch all recipes from the API
  Future<List> fetchAllRecipes() async {
    try {
      final response =
          await http.get(Uri.parse('https://api.mircofost.com/recipes/'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData.containsKey('data')) {
          if (mounted) {
            setState(() {
              _filteredRecipes = jsonData['data'];
            });
          }
          return jsonData['data'];
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
            'Failed to load recipes with status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load recipes: $e');
      }
      return [];
    }
  }

  // Method to fetch recipes based on provided ingredients
  Future<List> fetchRecipes(List<String>? ingredients) async {
    List<Map<String, dynamic>> transformedIngredients =
        ingredients?.map((ingredient) => {'Name': ingredient}).toList() ?? [];

    try {
      final response = await http.post(
        Uri.parse('https://api.mircofost.com/recipes/find/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'Ingredients': transformedIngredients,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData.containsKey('data')) {
          if (mounted) {
            setState(() {
              _filteredRecipes = jsonData['data'];
            });
          }
          return jsonData['data'];
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
            'Failed to load recipes with status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load recipes: $e');
      }
      return [];
    }
  }

  // Method to fetch filter options (allergens, devices, labels, nutrients) from the API
  Future<Map<String, dynamic>> fetchFilterOptions(String endpoint) async {
    try {
      final response =
          await http.get(Uri.parse('https://api.mircofost.com/$endpoint'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        throw Exception(
            'Failed to load filter options with status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load filter options: $e');
    }
  }

  // Method to initialize toggle states for filter categories
  void initializeToggleStates(String category, List<Map<String, dynamic>> data,
      Map<String, bool> toggleStates) {
    setState(() {
      toggleStates.addAll({
        for (var option in data) option['Name']: false // Use 'Name' as the key
      });
    });
    if (kDebugMode) {
      print(data);
    }
  }

  // Method to build the JSON body for applying filters
  Map<String, dynamic> buildFilterJsonBody() {
    Map<String, dynamic> filterJson = {};

    // Add active allergens to the filter JSON
    filterJson['Allergens'] = allergens['data']
        .where((option) => _allergensToggleStates[option['Name']] ?? false)
        .map((option) => {'Name': option['Name']})
        .toList();

    // Add active devices to the filter JSON
    filterJson['Devices'] = devices['data']
        .where((option) => _devicesToggleStates[option['Name']] ?? false)
        .map((option) => {'Name': option['Name']})
        .toList();

    // Add active labels to the filter JSON
    filterJson['Labels'] = labels['data']
        .where((option) => _labelsToggleStates[option['Name']] ?? false)
        .map((option) => {'Name': option['Name']})
        .toList();

    // Add active nutrients to the filter JSON
    filterJson['Nutrients'] = nutrients['data']
        .where((option) => _nutrientsToggleStates[option['Name']] ?? false)
        .map((option) => {'Name': option['Name']})
        .toList();

    return filterJson;
  }

  // Method to apply filters and fetch filtered recipes
  Future<void> applyFilters(Map<String, dynamic> filterJson) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.mircofost.com/recipes/find/Filter'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(filterJson),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.containsKey('data')) {
          if (mounted) {
            setState(() {
              _filteredRecipes = jsonResponse['data'];
            });
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
            'Failed to apply filters with status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('An error occurred while applying filters: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: loadedRecepies,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: Lottie.asset(
            'assets/loadingIndicator.json',
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.5,
          ));
        } else if (snapshot.hasError) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // Center the children vertically
            children: [
              Lottie.asset(
                'assets/loadingIndicator.json',
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.5,
              ),
              const Text(
                "Check your Connection!",
                style: TextStyle(
                  color: Color(0xFFA4C787),
                  fontSize: 26,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        } else {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                        left: 15, right: 15, top: 15, bottom: 5),
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _filteredRecipes = snapshot.data!
                                    .where((recipe) => recipe['Name']
                                        .toLowerCase()
                                        .contains(value.toLowerCase()))
                                    .toList();
                              });
                            },
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Suche ...',
                              hintStyle: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon:
                                  const Icon(Icons.search, color: Colors.white),
                              filled: true,
                              fillColor: const Color(0xFFA4C787),
                              contentPadding: const EdgeInsets.only(
                                  top: 5, bottom: 5, left: 25),
                            ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showFilterOptions =
                                  !_showFilterOptions; // Toggle the visibility of filter options
                            });
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA4C787),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  if (_showFilterOptions)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Theme(
                                data: Theme.of(context)
                                    .copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Allergene',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          spacing: 8.0,
                                          runSpacing: 4.0,
                                          children: allergens['data']
                                              .map<Widget>((option) =>
                                                  _buildToggleButton(option,
                                                      _allergensToggleStates))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              Theme(
                                data: Theme.of(context)
                                    .copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Hilfsmittel',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          spacing: 8.0,
                                          runSpacing: 4.0,
                                          children: devices['data']
                                              .map<Widget>((option) =>
                                                  _buildToggleButton(option,
                                                      _devicesToggleStates))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              Theme(
                                data: Theme.of(context)
                                    .copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Eigenschaften',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          spacing: 8.0,
                                          runSpacing: 4.0,
                                          children: labels['data']
                                              .map<Widget>((option) =>
                                                  _buildToggleButton(option,
                                                      _labelsToggleStates))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              Theme(
                                data: Theme.of(context)
                                    .copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Nährwerte',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          spacing: 8.0,
                                          runSpacing: 4.0,
                                          children: nutrients['data']
                                              .map<Widget>((option) =>
                                                  _buildToggleButton(option,
                                                      _nutrientsToggleStates))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Construct the filter JSON body
                                    Map<String, dynamic> filterJson =
                                        buildFilterJsonBody();

                                    // Apply the filters by calling the new method
                                    await applyFilters(filterJson);

                                    // Close the filter section and display filtered recipes
                                    setState(() {
                                      _showFilterOptions = false;
                                    });
                                  },
                                  child: const Text('Filter now'),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        var recipe = _filteredRecipes[index];
                        var images = recipe['images'];
                        String imageUrl;
                        if (images != null && images.isNotEmpty) {
                          imageUrl = images[0]['SmallImage'] ?? '';
                        } else {
                          imageUrl = 'api.mircofost.com/uploads/no-image.png';
                        }
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(
                                  recipeID: recipe['RecipeId'] ?? '',
                                ),
                              ),
                            );
                          },
                          child: RecipeCard(
                            title: recipe['Name'] ?? '',
                            description: recipe['Description'] ?? '',
                            imageUrl: imageUrl,
                            difficulty: recipe['Difficulty'],
                            caloriesPerPortion: recipe['CaloriesPerPortion'],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildToggleButton(dynamic option, Map<String, bool> toggleStates) {
    String name = option['Name']; // Use the 'Name' field as the key
    bool isToggledOn =
        toggleStates[name] ?? false; // Retrieve toggle state using 'Name'

    return InkWell(
      onTap: () {
        setState(() {
          toggleStates[name] =
              !isToggledOn; // Update the toggle state using 'Name'
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isToggledOn ? const Color(0xFFA4C787) : Colors.white,
              border: Border.all(width: 1, color: Colors.grey),
              borderRadius: BorderRadius.circular(25.0),
            ),
            child: Text(
              name, // Display the 'Name' field as the button text
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final int difficulty;
  final String caloriesPerPortion;

  const RecipeCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.difficulty,
    required this.caloriesPerPortion,
  });

  @override
  Widget build(BuildContext context) {
    String svgDifficulty;

    switch (difficulty) {
      case 1:
        svgDifficulty = 'assets/card/difficulty_1.svg';
        break;
      case 2:
        svgDifficulty = 'assets/card/difficulty_2.svg';
        break;
      case 3:
        svgDifficulty = 'assets/card/difficulty_3.svg';
        break;
      case 4:
        svgDifficulty = 'assets/card/difficulty_4.svg';
        break;
      case 5:
        svgDifficulty = 'assets/card/difficulty_5.svg';
        break;
      default:
        svgDifficulty = 'assets/card/difficulty_5.svg';
    }

    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, top: 6, bottom: 6),
      width: 359,
      height: 97,
      decoration: BoxDecoration(
        color: const Color(0xFFC5DAB0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(2, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 15, bottom: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 134,
                    child: Text(
                      title,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w800,
                        height: 0,
                      ),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 134,
                    height: 30,
                    child: Text(
                      description,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 8,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w300,
                        height: 0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: SvgPicture.asset(svgDifficulty),
                  ),
                  const SizedBox(height: 3),
                  const SizedBox(
                    child: Text(
                      'Schwierigkeit',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 6,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        height: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Wrap fire-solid SVG and text in a Column
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: SvgPicture.asset('assets/card/fire-solid.svg'),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 3),
                      Text(
                        '${caloriesPerPortion.substring(0, caloriesPerPortion.indexOf('.'))} kcal',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 6,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w600,
                          height: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 15),
          Container(
            width: 155,
            height: 97,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: 'https://$imageUrl',
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.fill,
              ),
            ),
          )
        ],
      ),
    );
  }
}

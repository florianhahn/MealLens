import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailPage extends StatefulWidget {
  final int recipeID;

  const DetailPage({
    super.key,
    required this.recipeID,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final TextEditingController _portionsController =
      TextEditingController(text: '1');
  late Map<String, dynamic> recipeData;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails().then((data) {
      setState(() {
        recipeData = data;
      });
    });
  }

  // Fetches recipe details from the API
  Future<Map<String, dynamic>> _fetchRecipeDetails() async {
    try {
      final response = await http.get(
          Uri.parse('https://api.mircofost.com/recipes/${widget.recipeID}'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load recipe details with status code: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recipe details: $e');
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Details zum Rezept',
          style: TextStyle(fontFamily: 'Lato'),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchRecipeDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Lottie.asset(
                'assets/loadingIndicator.json',
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.5,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final recipeData = snapshot.data!['data'];

            String svgDifficulty;

            // Determine SVG icon for difficulty level
            switch (recipeData['Difficulty']) {
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

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 250,
                        child: CachedNetworkImage(
                          imageUrl: snapshot.data?['data']['images'].isNotEmpty
                              ? 'https://${snapshot.data?['data']['images'][0]['BigImage']}'
                              : 'https://api.mircofost.com/uploads/no-image.png',
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                          fit: BoxFit.fill,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    recipeData['Name'],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w800,
                                      height: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 30,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: const BoxDecoration(),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                left: 0,
                                                top: 0,
                                                child: SizedBox(
                                                  width: 28,
                                                  height: 30,
                                                  child: SvgPicture.asset(
                                                      svgDifficulty),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        const SizedBox(
                                          height: 10,
                                          child: Text(
                                            'Schwierigkeit',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontFamily: 'Lato',
                                              fontWeight: FontWeight.w700,
                                              height: 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 30,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: const BoxDecoration(),
                                          child: SvgPicture.asset(
                                              'assets/card/fire-solid.svg'),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${recipeData['CaloriesPerPortion'].substring(0, recipeData['CaloriesPerPortion'].indexOf('.'))} kcal',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.w700,
                                            height: 0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 13),
                            SizedBox(
                              child: Text(
                                recipeData['Description'],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w300,
                                  height: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: const ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    strokeAlign: BorderSide.strokeAlignCenter,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                const SizedBox(
                                  height: 33,
                                  child: Text(
                                    'Zutaten',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w600,
                                      height: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 100),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA4C787),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Portionen',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.w300,
                                          height: 0,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 5),
                                        child: SizedBox(
                                          width: 40,
                                          child: TextField(
                                            controller: _portionsController,
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 16),
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.all(2),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.black),
                                              ),
                                            ),
                                            onSubmitted: (value) {
                                              setState(
                                                  () {}); // This will trigger a rebuild of the widget
                                            },
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                  recipeData['ingredients'].length, (index) {
                                var ingredient =
                                    recipeData['ingredients'][index];
                                double amount = double.tryParse(
                                        ingredient['hasingredient']
                                            ['Amount']) ??
                                    0;
                                double portions =
                                    double.tryParse(_portionsController.text) ??
                                        1;
                                double calculatedAmount = amount * portions;

                                NumberFormat format =
                                    NumberFormat('#,##0.##', 'de_DE');
                                String formattedAmount =
                                    format.format(calculatedAmount);

                                final isFirstItem = index == 0;
                                final isLastItem = index ==
                                    recipeData['ingredients'].length - 1;

                                return Container(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    left: 8,
                                    right: 29,
                                    bottom: 10,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: index % 2 == 0
                                        ? const Color(0xFFC5DAB0)
                                        : const Color(0xFFA4C787),
                                    // alternate colors
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: isFirstItem
                                            ? const Radius.circular(12)
                                            : Radius.zero,
                                        bottom: isLastItem
                                            ? const Radius.circular(12)
                                            : Radius.zero,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          formattedAmount,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.w300,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          ingredient['hasingredient']['Unit'],
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.w400,
                                            height:
                                                1.2, // Adjust height as per your needs
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        child: Text(
                                          ingredient['Name'],
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 20),
                            const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: 8),
                                  SizedBox(
                                    height: 33,
                                    child: Text(
                                      'Zubereitung',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.w600,
                                        height: 0,
                                      ),
                                    ),
                                  ),
                                ]),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  recipeData['preparations'].length,
                                  (index) {
                                    var preparation =
                                        recipeData['preparations'][index];

                                    return SizedBox(
                                      width: double.infinity,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color(0xFFA4C787),
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Schritt ${preparation['Step'].toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontFamily: 'Lato',
                                                fontWeight: FontWeight.w600,
                                                height: 0,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              preparation['Text'],
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontFamily: 'Lato',
                                                fontWeight: FontWeight.w300,
                                                height: 0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

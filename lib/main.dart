import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meallens_app/camera.dart';
import 'package:meallens_app/list.dart';
import 'package:meallens_app/meallens.dart';
import 'package:flutter/services.dart';
import 'package:meallens_app/menueprovider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => MenueProvider(),
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MealLens',
      theme: ThemeData(
        fontFamily: 'Lato', // Set the global font family
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA4C787)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MealLens Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _widgetOptions = [
    MealLensPage(),
    const CameraPage(),
    const RecipeList()
  ];
  late MenueProvider _menueProvider;

  @override
  void initState() {
    super.initState();
    _menueProvider = Provider.of<MenueProvider>(context, listen: false);
  }

  void _onItemTapped(int index) {
    setState(() {
      _menueProvider.setSelectedIndex(index);
      _menueProvider.pageController.animateToPage(
        _menueProvider.selectedIndex,
        duration: const Duration(milliseconds: 150),
        curve: Curves.linear,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFFA4C787),
    ));
    return Scaffold(
      body: PageView(
        onPageChanged: (index) {
          setState(() {
            _menueProvider.setSelectedIndex(index);
          });
        },
        controller: _menueProvider.pageController,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFA4C787),
        ),
        height: 40,
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: <BottomNavigationBarItem>[
            _buildBottomNavigationBarItem(
              index: 0,
              solidIconPath: 'assets/MealLens_Solid.svg',
              lineIconPath: 'assets/MealLens_linie.svg',
            ),
            _buildBottomNavigationBarItem(
              index: 1,
              solidIconPath: 'assets/Kamera_Solid.svg',
              lineIconPath: 'assets/Kamere_Linie.svg',
            ),
            _buildBottomNavigationBarItem(
              index: 2,
              solidIconPath: 'assets/List_Solid.svg',
              lineIconPath: 'assets/List_Linie.svg',
            ),
          ],
          currentIndex: _menueProvider.selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required int index,
    required String solidIconPath,
    required String lineIconPath,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: SvgPicture.asset(
          _menueProvider.selectedIndex == index ? solidIconPath : lineIconPath,
          // ignore: deprecated_member_use
          color: Colors.white,
          height: 24.0,
        ),
      ),
      label: '',
    );
  }
}

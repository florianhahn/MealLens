import 'package:flutter/material.dart';

class MealLensPage extends StatelessWidget {
  final ScrollController scrollController = ScrollController();

  MealLensPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.bottomLeft,
                      children: <Widget>[
                        Container(
                          height: 16,
                          // Adjust this value to change the height of the container
                          color: const Color(0xFFC5DAB0),
                          child: const Text(
                            '                  ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Text(
                          ' Über uns ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Was ist MealLens?',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Lato',
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 5),
                    const Text(
                        'Heutzutage ist Lebensmittelverschwendung, vor allem im eigenen Haushalt, ein immer größeres Problem. Die App „MealLens“ ermöglicht es, ohne viel Aufwand Lebensmittel mit leckeren Kochrezepten zu verwerten.',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w300)),
                    const SizedBox(height: 10),
                    Padding(
                        padding: const EdgeInsets.only(right: 80),
                        child: Image.asset('assets/logo_main.jpg')),
                    const SizedBox(height: 10),
                    const Text('Wie funktioniert MealLens?',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Lato',
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 5),
                    const Text(
                        'Du machst einfach mit deinem Handy ein Foto vom Kühlschrankinhalt und die App macht den Rest! Mittels künstlicher Intelligenz werden die Lebensmittel erkannt und dir werden schnell Rezepte, die diese beinhalten, vorgeschlagen.',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Stack(
                alignment: Alignment.bottomLeft,
                children: <Widget>[
                  Container(
                    height: 16,
                    // Adjust this value to change the height of the container
                    color: const Color(0xFFC5DAB0),
                    child: const Text(
                      '                 ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Text(
                    ' Tutorial ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: tutorialSteps
                    .asMap()
                    .entries
                    .map((entry) => MyExpansionTileItem(
                          title: entry.value.title,
                          content: entry.value.content,
                          stepNumber: entry.key + 1,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyExpansionTileItem extends StatefulWidget {
  final String title;
  final String content;
  final int stepNumber;

  const MyExpansionTileItem({
    super.key,
    required this.title,
    required this.content,
    required this.stepNumber,
  });

  @override
  // ignore: library_private_types_in_public_api
  _MyExpansionTileItemState createState() => _MyExpansionTileItemState();
}

class _MyExpansionTileItemState extends State<MyExpansionTileItem> {
  late GlobalKey _expansionTileKey;

  @override
  void initState() {
    super.initState();
    _expansionTileKey = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFC5DAB0),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: _expansionTileKey,
          backgroundColor: const Color(0xFFC5DAB0),
          title: Text(
            '${widget.stepNumber}. ${widget.title}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Lato',
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          onExpansionChanged: (bool expanded) {
            if (expanded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Scrollable.ensureVisible(
                  _expansionTileKey.currentContext!,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            }
          },
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 4,
                bottom: 16,
              ),
              child: Text(
                widget.content,
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Lato',
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String content;

  TutorialStep({required this.title, required this.content});
}

List<TutorialStep> tutorialSteps = [
  TutorialStep(
    title: 'Zugriff auf die Kamera',
    content:
        'Erlaube der App den Zugriff auf die Kamera deines Handys. Dies ist notwendig, um Fotos von deinem Kühlschrankinhalt aufnehmen zu können.',
  ),
  TutorialStep(
    title: 'Fotografieren des Kühlschrankinhalts',
    content:
        'Öffne deinen Kühlschrank und positioniere dein Handy so, dass der gesamte Inhalt gut sichtbar ist. Drücke den Kamera-Button in der App, um ein Foto aufzunehmen.',
  ),
  TutorialStep(
    title: 'Verarbeitung durch KI',
    content:
        'Die App analysiert das aufgenommene Foto mithilfe von künstlicher Intelligenz. Dieser Schritt kann einige Augenblicke in Anspruch nehmen, abhängig von der Menge der erkannten Lebensmittel.',
  ),
  TutorialStep(
    title: 'Anzeige der erkannten Lebensmittel',
    content:
        'Die App listet die erkannten Lebensmittel auf und gibt dir die Möglichkeit, fehlende oder falsch erkannte Produkte manuell zu korrigieren.',
  ),
  TutorialStep(
    title: 'Vorschläge für Rezepte',
    content:
        'Nach erfolgreicher Erkennung zeigt die App dir eine Liste von Rezepten an, die du mit den erkannten Lebensmitteln zubereiten kannst. Du kannst die Rezepte nach verschiedenen Kriterien filtern, wie z.B. Schwierigkeitsgrad oder Zubereitungszeit.',
  ),
  TutorialStep(
    title: 'Auswahl und Anzeige eines Rezepts',
    content:
        'Wähle ein Rezept aus der Liste aus, um detaillierte Anweisungen, Zutatenliste und Zubereitungsschritte anzuzeigen. Die App ermöglicht es dir auch, fehlende Zutaten zu einer Einkaufsliste hinzuzufügen.',
  ),
  TutorialStep(
    title: 'Zubereitung des Rezepts',
    content:
        'Folge den Schritten in der Rezeptanleitung, um das ausgewählte Gericht zuzubereiten. Die App bietet möglicherweise auch Tipps und Variationen für das Rezept an.',
  ),
  TutorialStep(
    title: 'Genieße deine Mahlzeit',
    content:
        'Nachdem du das Rezept erfolgreich zubereitet hast, kannst du deine selbstgemachte Mahlzeit genießen! Du kannst die App bei Bedarf erneut verwenden, um den Kühlschrankinhalt zu überprüfen und weitere Rezeptideen zu erhalten.',
  ),
];

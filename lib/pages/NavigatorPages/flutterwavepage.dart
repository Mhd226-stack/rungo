import 'package:flutter/material.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';

class FlutterWavePage extends StatefulWidget {
  dynamic from;
  FlutterWavePage({this.from, Key? key}) : super(key: key);

  @override
  State<FlutterWavePage> createState() => _FlutterWavePageState();
}

class _FlutterWavePageState extends State<FlutterWavePage> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: page,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: media.width * 0.2, color: buttonColor),
            SizedBox(height: media.width * 0.05),
            Text(
              languages[choosenLanguage]['text_somethingwentwrong'] ?? 'Paiement indisponible',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            SizedBox(height: media.width * 0.05),
            Button(
              onTap: () => Navigator.pop(context, false),
              text: languages[choosenLanguage]['text_ok'] ?? 'OK',
            )
          ],
        ),
      ),
    );
  }
}
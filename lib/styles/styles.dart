import 'package:flutter/material.dart';

var scrheight = 813.0;
var scrwidth = 375.0;

double eight = 0.0213;
double ten = 0.0267;
double twelve = 0.032;
double fourteen = 0.037;
double thirty = 0.08;
double fifteen = 0.04;
double sixteen = 0.042666;
double eighteen = 0.048;
double twenty = 0.053;
double twentysix = 0.0693;
double twentyeight = 0.07466;
double twentyfour = 0.064;
double fourty = 0.10667;
double one = 0.00267;
double two = 0.00534;
double three = 0.008;
double four = 0.01067;
double five = 0.01334;
double six = 0.016;
double seven = 0.01867;
double nine = 0.024;
double eleven = 0.02934;
double thirteen = 0.03467;
double seventeen = 0.04534;
double nineteen = 0.05067;
double twentyone = 0.056;
double twentytwo = 0.05867;
double twentythree = 0.06134;
double twentyfive = 0.06667;
double twentyseven = 0.072;
double twentynine = 0.07734;
double thirtyone = 0.08267;
double thirtytwo = 0.08534;
double thirtythree = 0.088;
double thirtyfour = 0.09067;
double thirtyfive = 0.09334;
double thirtysix = 0.096;
double thirtyseven = 0.09867;
double thirtyeight = 0.10134;
double thirtynine = 0.104;

// ── état du thème ──
bool isDarkTheme = false;

// ── couleurs fixes (identiques en dark et light) ──
Color buttonColor = const Color(0xffFFB800);   // rouge Rungo
Color theme      = const Color(0xffFFB800);
Color buttonText = const Color(0xffFFFFFF);
Color starColor  = const Color(0xffFac500);
Color loaderColor = const Color(0xffFFB800);
Color online     = const Color(0xff2ECC71);     // vert Rungo
Color offline    = const Color(0xff898989);
Color onlineOfflineText = const Color(0xffFFFFFF);
Color verifyPending    = const Color(0xffFFB800);
Color verifyDeclined   = const Color(0xffE70000);
Color notUploadedColor = Colors.orange;
Color white = Colors.white;
Color black = Colors.black;
Color inputFieldSeparator = const Color(0xff1DA1F2);
Color termsCheckBox = const Color(0xffFFB800);

// ── couleurs dark mode fixes ──
Color darkModeBackground    = const Color(0xff0D0D0D);
Color darkModeSecContainer  = const Color(0xff191B1A);
Color darkModeBorderColor   = const Color.fromARGB(30, 255, 255, 255);
Color darkModeDialogColor   = const Color(0xff1A1A1A);
Color darkModeSenderTextColor = const Color.fromRGBO(139, 26, 26, 0.2);

// ══════════════════════════════════════════════
//  COULEURS DYNAMIQUES — changent selon le thème
//  Appelle setTheme(isDark) pour les mettre à jour
// ══════════════════════════════════════════════

// Fond principal
Color page = const Color(0xffFBFBFB);

// Barre du haut
Color topBar = const Color(0xffFFFFFF);

// Texte principal
Color textColor = const Color(0xff191B1A);

// Fond général
Color backgroundColor = const Color(0xffe5e5e5);

// Icône retour
Color backIcon = const Color(0xff12121D);

// Hint / placeholder
Color hintColor = const Color(0xff12121D).withOpacity(0.3);

// Soulignements
Color underline       = const Color(0xff12121D).withOpacity(0.3);
Color inputUnderline  = const Color(0xff12121D).withOpacity(0.3);
Color inputfocusedUnderline = const Color(0xff12121D);

// Bordures
Color borderLines = const Color(0xffE5E5E5);

// Fond vérification en attente
Color verifyPendingBck = const Color(0xffFEF2F2);

// Dégradé de fond
List<Color> backgroundGradient = [
  const Color(0xffFFFFFF),
  const Color(0xffFFB800),
];

// ══════════════════════════════════════════════
//  FONCTION DE MISE À JOUR DU THÈME
// ══════════════════════════════════════════════
void setTheme(bool dark) {
  isDarkTheme = dark;

  if (dark) {
    // ── DARK MODE ──
    page                   = const Color(0xff0D0D0D);
    topBar                 = const Color(0xff1A1A1A);
    textColor              = const Color(0xffF5F5F5);
    backgroundColor        = const Color(0xff121212);
    backIcon               = const Color(0xffF5F5F5);
    hintColor              = const Color(0xffF5F5F5).withOpacity(0.3);
    underline              = const Color(0xffF5F5F5).withOpacity(0.2);
    inputUnderline         = const Color(0xffF5F5F5).withOpacity(0.2);
    inputfocusedUnderline  = const Color(0xffF5F5F5);
    borderLines            = const Color(0xff2A2A2A);
    verifyPendingBck       = const Color(0xff1A1A1A);
    backgroundGradient     = [
      const Color(0xff0D0D0D),
      const Color(0xffFFB800),
    ];
    darkModeDialogColor    = const Color(0xff1A1A1A);
    darkModeBorderColor    = const Color.fromARGB(40, 255, 255, 255);
  } else {
    // ── LIGHT MODE ──
    page                   = const Color(0xffFBFBFB);
    topBar                 = const Color(0xffFFFFFF);
    textColor              = const Color(0xff191B1A);
    backgroundColor        = const Color(0xffe5e5e5);
    backIcon               = const Color(0xff12121D);
    hintColor              = const Color(0xff12121D).withOpacity(0.3);
    underline              = const Color(0xff12121D).withOpacity(0.3);
    inputUnderline         = const Color(0xff12121D).withOpacity(0.3);
    inputfocusedUnderline  = const Color(0xff12121D);
    borderLines            = const Color(0xffE5E5E5);
    verifyPendingBck       = const Color(0xffFEF2F2);
    backgroundGradient     = [
      const Color(0xffFFFFFF),
      const Color(0xffFFB800),
    ];
    darkModeDialogColor    = const Color(0xffFFFFFF);
    darkModeBorderColor    = const Color.fromARGB(20, 0, 0, 0);
  }
}
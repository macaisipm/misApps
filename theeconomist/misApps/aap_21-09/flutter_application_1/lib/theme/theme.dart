import 'package:flutter/material.dart';

class AppColors {
  // Primary
  
  static const primary100 = Color(0xFFFCCDCC);
  static const primary200 = Color(0xFFFA9B98);
  static const primary300 = Color(0xFFF76965);
  static const primary400 = Color(0xFFF33731);
  static const primary500 = Color(0xFFE3130C); // BASE
  static const primary600 = Color(0xFFBA100A);
  static const primary700 = Color(0xFF920C08);
  static const primary800 = Color(0xFF690906);

  // Secondary

  static const secondary100 = Color(0xFFBAABF1);
  static const secondary200 = Color(0xFF9881EA);
  static const secondary300 = Color(0xFF7657E3); // BASE
  static const secondary400 = Color(0xFF532DDB);
  static const secondary500 = Color(0xFF411FB8);
  static const secondary600 = Color(0xFF32188E);
  static const secondary700 = Color(0xFF241166);
  static const secondary800 = Color(0xFF160A3E);

  // Tertiary

  static const tertiary100 = Color(0xFFF5F4EE); // BASE
  static const tertiary200 = Color(0xFFE2DFCE);
  static const tertiary300 = Color(0xFFCFCBAE);
  static const tertiary400 = Color(0xFFBDB68E);
  static const tertiary500 = Color(0xFFAAA16E);
  static const tertiary600 = Color(0xFF908855);
  static const tertiary700 = Color(0xFF706942);
  static const tertiary800 = Color(0xFF504B2F);

  // Neutral

  static const neutral100 = Color(0xFFFFFFFF);
  static const neutral200 = Color(0xFFDBDBDB);
  static const neutral300 = Color(0xFFB6B6B6);
  static const neutral400 = Color(0xFF929292);
  static const neutral500 = Color(0xFF6D6D6D);
  static const neutral600 = Color(0xFF494949);
  static const neutral700 = Color(0xFF242424);
  static const neutral800 = Color(0xFF000000);

  // Error

  static const error100 = Color(0xFFFFCBC6);
  static const error200 = Color(0xFFFF978E);
  static const error300 = Color(0xFFFF6455);
  static const error400 = Color(0xFFFF301C); // BASE
  static const error500 = Color(0xFFF01500);
  static const error600 = Color(0xFFC51100);
  static const error700 = Color(0xFF9A0E00);
  static const error800 = Color(0xFF6F0A00);

  // Success

  static const success100 = Color(0xFFB3EFC4);
  static const success200 = Color(0xFF8CE8A7);
  static const success300 = Color(0xFF66E08A);
  static const success400 = Color(0xFF40D86C);
  static const success500 = Color(0xFF28C255);
  static const success600 = Color(0xFF209C44); // BASE
  static const success700 = Color(0xFF176F30);
  static const success800 = Color(0xFF0E421D);

  // Warning

  static const warning100 = Color(0xFFFEF0CB);
  static const warning200 = Color(0xFFFDE096);
  static const warning300 = Color(0xFFFCD162);
  static const warning400 = Color(0xFFFBC12D); // BASE
  static const warning500 = Color(0xFFF6B205);
  static const warning600 = Color(0xFFCA9204);
  static const warning700 = Color(0xFF9E7203);
  static const warning800 = Color(0xFF725202);

  // Information

  static const information100 = Color(0xFFCAEDFD);
  static const information200 = Color(0xFF94DAFB);
  static const information300 = Color(0xFF5FC8F8);
  static const information400 = Color(0xFF2AB5F6); // BASE
  static const information500 = Color(0xFF0AA3EA);
  static const information600 = Color(0xFF0886C0);
  static const information700 = Color(0xFF066996);
  static const information800 = Color(0xFF054B6C);
}

// tema audiomack
final ThemeData audiomack = ThemeData(
  useMaterial3: true,

  fontFamily: AppTypography.fontFamily,

  textTheme: const TextTheme(
    displayLarge: AppTypography.h1,
    displayMedium: AppTypography.h2,
    displaySmall: AppTypography.h3,
    headlineLarge: AppTypography.h4,
    headlineMedium: AppTypography.h5,
    headlineSmall: AppTypography.h6,
    titleLarge: AppTypography.h6,
    titleMedium: AppTypography.subtitle1,
    titleSmall: AppTypography.subtitle2,
    bodyLarge: AppTypography.body1,
    bodyMedium: AppTypography.body2,
    bodySmall: AppTypography.caption,
    labelLarge: AppTypography.button,
    labelSmall: AppTypography.overline,
  ),

  colorScheme: const ColorScheme.light(

    //Primary 
    primary: AppColors.primary500,
    onPrimary: AppColors.neutral100, 
    primaryContainer: AppColors.primary200,
    onPrimaryContainer: AppColors.primary600,

    //Secondary
    secondary: AppColors.secondary200,
    onSecondary: AppColors.neutral100,
    secondaryContainer: AppColors.secondary100,
    onSecondaryContainer: AppColors.secondary400,

    //Tertiary
    tertiary: AppColors.tertiary100,
    onTertiary: AppColors.neutral500,
    tertiaryContainer: AppColors.tertiary200,
    onTertiaryContainer: AppColors.tertiary400,

    //Error
    error: AppColors.error400,
    onError: AppColors.neutral100,
    errorContainer: AppColors.error300,
    onErrorContainer: AppColors.primary700,

    //Surface
    surface: AppColors.neutral100,
    onSurface: AppColors.neutral800,
  ),
);

class FeedbackColors{

  //Success
  static const Color success = Color(0xFF209C44);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFF8CE8A7);
  static const Color onSuccessContainer = Color(0xFF176F30);

  //Warning
  static const Color warning = Color(0xFFFBC12D);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFDE096);
  static const Color onWarningContainer = Color(0xFFCA9204);

  //Information
  static const Color information = Color(0xFF2AB5F6);
  static const Color onInformation = Color(0xFFFFFFFF);
  static const Color informationContainer = Color(0xFF94DAFB);
  static const Color onInformationContainer = Color(0xFF066996);
}


class AppTypography {
    
    static const String fontFamily = 'Barlow Condensed';

    //H1
    static const TextStyle h1 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 102,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
    );

    //H2
    static const TextStyle h2 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 64,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
    );
    
    //H3
    static const TextStyle h3 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 51,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
    );

    //H4
    static const TextStyle h4 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
    );

    //H5
    static const TextStyle h5 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
    );
    
    //H6
    static const TextStyle h6 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 21,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
    );

    //Subtitle1
    static const TextStyle subtitle1 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
    );

    //Subtitle2
    static const TextStyle subtitle2 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
    );

    //Body1
    static const TextStyle body1 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
    );
    
    //Body2
    static const TextStyle body2 = TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
    );

    //BUTTON
    static const TextStyle button = TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
    );

    //Caption
    static const TextStyle caption = TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
    );

    //OVERLINE
    static const TextStyle overline = TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
    );
    
}

class AppSpacing {
    static const double xs4 = 4; 
    static const double sm8 = 8; 
    static const double md16 = 16;
    static const double lg24 = 24;
    static const double xl32 = 32;
    static const double xxl48 = 48;
    
}

class AppPadding {
    static const double xs4 = 4;
    static const double sm8 = 8;
    static const double md12 = 12;
    static const double lg16 = 16;
    static const double xl20 = 20;
}

class AppMargin {
    static const double tight12 = 12;
    static const double default16 = 16;
    static const double relaxed24 = 24;
    static const double spacious32 = 32;
    static const double wide48 = 48;
}

class AppGap {
    static const double compact4 = 4;
    static const double normal8 = 8;
    static const double spacious16 = 16;
    static const double wide24 = 24;
    static const double extra48 = 48;
}

class AppShapes {
    static const double radius4 = 4;
    static const double radius8 = 8;
    static const double radius16 = 16;
    static const double radius24 = 24;
}
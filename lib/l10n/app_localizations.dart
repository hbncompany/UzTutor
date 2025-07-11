import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:repetitor_resurs/l10n/app_strings.dart'; // Янги импорт

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  // Таржима функцияси
  String translate(String key, {Map<String, dynamic>? args}) {
    return AppStrings.get(key, locale.languageCode, args: args);
  }

  // Қуйидаги getter функцияларини translate функцияси орқали чақиринг
  String get appName => translate('appName');
  String get welcomeTitle => translate('welcomeTitle');
  String get welcomeText1 => translate('welcomeText1');
  String get welcomeText2 => translate('welcomeText2');
  String get welcomeText3 => translate('welcomeText3');
  String get continueButton => translate('continueButton');
  String get loginRegisterTitle => translate('loginRegisterTitle');
  String get emailHint => translate('emailHint');
  String get passwordHint => translate('passwordHint');
  String get loginButton => translate('loginButton');
  String get registerButton => translate('registerButton');
  String get continueAsGuest => translate('continueAsGuest');
  String get userTypeClient => translate('userTypeClient');
  String get userTypeTutor => translate('userTypeTutor');
  String get selectUserType => translate('selectUserType');
  String get registerSuccess => translate('registerSuccess');
  String get loginSuccess => translate('loginSuccess');
  String get guestLoginSuccess => translate('guestLoginSuccess');
  String errorLogin(String error) =>
      translate('errorLogin', args: {'error': error});
  String errorRegister(String error) =>
      translate('errorRegister', args: {'error': error});
  String get findTutor => translate('findTutor');
  String get findResources => translate('findResources');
  String helloUser(String userName) =>
      translate('helloUser', args: {'userName': userName});
  String get myProfile => translate('myProfile');
  String get appLanguage => translate('appLanguage');
  String get appTheme => translate('appTheme');
  String get contactDeveloper => translate('contactDeveloper');
  String get logout => translate('logout');
  String get uzbek => translate('uzbek');
  String get russian => translate('russian');
  String get english => translate('english');
  String get lightTheme => translate('lightTheme');
  String get darkTheme => translate('darkTheme');
  String get tutorsListTitle => translate('tutorsListTitle');
  String get searchHint => translate('searchHint');
  String get allRatings => translate('allRatings');
  String ratingAbove(int rating) =>
      translate('ratingAbove', args: {'rating': rating});
  String get noTutorsFound => translate('noTutorsFound');
  String pricePerHour(double price) => translate('pricePerHour',
      args: {'price': price.toStringAsFixed(2)}); // price.toStringAsFixed(2)
  String get viewProfile => translate('viewProfile');
  String get addReview => translate('addReview');
  String get noReviews => translate('noReviews');
  String get reviewPlaceholder => translate('reviewPlaceholder');
  String get ratingPlaceholder => translate('ratingPlaceholder');
  String get submitReview => translate('submitReview');
  String get reviewSuccess => translate('reviewSuccess');
  String reviewError(String error) =>
      translate('reviewError', args: {'error': error});
  String get tutorProfileTitle => translate('tutorProfileTitle');
  String get description => translate('description');
  String get reviews => translate('reviews');
  String get contactTutor => translate('contactTutor');
  String get backButton => translate('backButton');
  String chatWith(String tutorName) =>
      translate('chatWith', args: {'tutorName': tutorName});
  String get messageHint => translate('messageHint');
  String get sendButton => translate('sendButton');
  String get noMessages => translate('noMessages');
  String get resourcesTitle => translate('resourcesTitle');
  String get resourcesPlaceholder => translate('resourcesPlaceholder');
  String get contactTitle => translate('contactTitle');
  String get contactText => translate('contactText');
  String get contactEmail => translate('contactEmail');
  String get contactPhone => translate('contactPhone');
  String get addTutor => translate('addTutor');
  String get nameLabel => translate('nameLabel');
  String get subjectLabel => translate('subjectLabel');
  String get ratingLabel => translate('ratingLabel');
  String get priceLabel => translate('priceLabel');
  String get descriptionLabel => translate('descriptionLabel');
  String get imageUrlLabel => translate('imageUrlLabel');
  String get add => translate('add');
  String get tutorAddedSuccess => translate('tutorAddedSuccess');
  String tutorAddError(String error) =>
      translate('tutorAddError', args: {'error': error});
  String get loading => translate('loading');
  String get errorLoadingTutors => translate('errorLoadingTutors');
  String get tutorNotFound => translate('tutorNotFound');
  String get loginRequiredReview => translate('loginRequiredReview');
  String errorSendingMessage(String error) =>
      translate('errorSendingMessage', args: {'error': error});
  String get chatLoading => translate('chatLoading');
  String get errorLoadingChat => translate('errorLoadingChat');
  String get userNotFound => translate('userNotFound');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

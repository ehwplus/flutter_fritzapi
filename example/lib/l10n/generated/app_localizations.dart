import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de')];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'FRITZ!API Demo App'**
  String get appTitle;

  /// No description provided for @detectTitle.
  ///
  /// In de, this message translates to:
  /// **'FRITZ!Box erkennen'**
  String get detectTitle;

  /// No description provided for @baseUrlLabel.
  ///
  /// In de, this message translates to:
  /// **'Base URL'**
  String get baseUrlLabel;

  /// No description provided for @baseUrlHelper.
  ///
  /// In de, this message translates to:
  /// **'Standard: http://fritz.box'**
  String get baseUrlHelper;

  /// No description provided for @detectFound.
  ///
  /// In de, this message translates to:
  /// **'FRITZ!Box gefunden.'**
  String get detectFound;

  /// No description provided for @detectSearching.
  ///
  /// In de, this message translates to:
  /// **'Suche nach FRITZ!Box...'**
  String get detectSearching;

  /// No description provided for @detectSearchingShort.
  ///
  /// In de, this message translates to:
  /// **'Suche...'**
  String get detectSearchingShort;

  /// No description provided for @detectRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut suchen'**
  String get detectRetry;

  /// No description provided for @detectErrorWithUrl.
  ///
  /// In de, this message translates to:
  /// **'Keine FRITZ!Box unter {baseUrl} gefunden.'**
  String detectErrorWithUrl(Object baseUrl);

  /// No description provided for @detectErrorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Verbindungsprüfung fehlgeschlagen: {error}'**
  String detectErrorGeneric(Object error);

  /// No description provided for @connectedStatus.
  ///
  /// In de, this message translates to:
  /// **'Verbunden mit {baseUrl}'**
  String connectedStatus(Object baseUrl);

  /// No description provided for @connectedLoggedInTitle.
  ///
  /// In de, this message translates to:
  /// **'Verbunden und angemeldet'**
  String get connectedLoggedInTitle;

  /// No description provided for @sidLabel.
  ///
  /// In de, this message translates to:
  /// **'SID: {sid}'**
  String sidLabel(Object sid);

  /// No description provided for @logoutButton.
  ///
  /// In de, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @loginTitle.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get loginTitle;

  /// No description provided for @passwordLabel.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get passwordLabel;

  /// No description provided for @usernameLabel.
  ///
  /// In de, this message translates to:
  /// **'Benutzername (optional)'**
  String get usernameLabel;

  /// No description provided for @loginButton.
  ///
  /// In de, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginButtonBusy.
  ///
  /// In de, this message translates to:
  /// **'Anmelden...'**
  String get loginButtonBusy;

  /// No description provided for @loginErrorNoConnection.
  ///
  /// In de, this message translates to:
  /// **'Bitte zuerst Verbindung prüfen.'**
  String get loginErrorNoConnection;

  /// No description provided for @loginErrorEmptyPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort darf nicht leer sein.'**
  String get loginErrorEmptyPassword;

  /// No description provided for @loginErrorInvalidCreds.
  ///
  /// In de, this message translates to:
  /// **'Login fehlgeschlagen. Bitte Benutzername/Passwort prüfen.'**
  String get loginErrorInvalidCreds;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Login fehlgeschlagen: {error}'**
  String loginErrorGeneric(Object error);

  /// No description provided for @devicesTitle.
  ///
  /// In de, this message translates to:
  /// **'Geräte & Daten'**
  String get devicesTitle;

  /// No description provided for @routerLabel.
  ///
  /// In de, this message translates to:
  /// **'Router'**
  String get routerLabel;

  /// No description provided for @routerDeviceTitle.
  ///
  /// In de, this message translates to:
  /// **'FRITZ!Box'**
  String get routerDeviceTitle;

  /// No description provided for @noCapabilities.
  ///
  /// In de, this message translates to:
  /// **'Keine Daten-Typen verfügbar.'**
  String get noCapabilities;

  /// No description provided for @temperatureLabel.
  ///
  /// In de, this message translates to:
  /// **'Temperatur'**
  String get temperatureLabel;

  /// No description provided for @humidityLabel.
  ///
  /// In de, this message translates to:
  /// **'Luftfeuchtigkeit'**
  String get humidityLabel;

  /// No description provided for @powerLabel.
  ///
  /// In de, this message translates to:
  /// **'Leistung'**
  String get powerLabel;

  /// No description provided for @onlineCounterLabel.
  ///
  /// In de, this message translates to:
  /// **'Online-Counter'**
  String get onlineCounterLabel;

  /// No description provided for @wifiClientsLabel.
  ///
  /// In de, this message translates to:
  /// **'WLAN-Clients'**
  String get wifiClientsLabel;

  /// No description provided for @loadingData.
  ///
  /// In de, this message translates to:
  /// **'Lade Daten...'**
  String get loadingData;

  /// No description provided for @errorWithMessage.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {message}'**
  String errorWithMessage(Object message);

  /// No description provided for @closeButton.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get closeButton;

  /// No description provided for @noData.
  ///
  /// In de, this message translates to:
  /// **'Keine Daten'**
  String get noData;

  /// No description provided for @historyTitle.
  ///
  /// In de, this message translates to:
  /// **'Historie'**
  String get historyTitle;

  /// No description provided for @historyEnergyMissing.
  ///
  /// In de, this message translates to:
  /// **'Keine historischen Energiedaten verfügbar.'**
  String get historyEnergyMissing;

  /// No description provided for @historyEnergy.
  ///
  /// In de, this message translates to:
  /// **'Heute: {dayWh} Wh\nMonat: {monthWh} Wh\nJahr: {yearWh} Wh'**
  String historyEnergy(Object dayWh, Object monthWh, Object yearWh);

  /// No description provided for @historyPowerEntry.
  ///
  /// In de, this message translates to:
  /// **'{range}: {value} Wh'**
  String historyPowerEntry(Object range, Object value);

  /// No description provided for @historySensorEntry.
  ///
  /// In de, this message translates to:
  /// **'{range}: {value}'**
  String historySensorEntry(Object range, Object value);

  /// No description provided for @currentPower.
  ///
  /// In de, this message translates to:
  /// **'Leistung: {value} W'**
  String currentPower(Object value);

  /// No description provided for @currentTemperature.
  ///
  /// In de, this message translates to:
  /// **'Temperatur: {value} °C'**
  String currentTemperature(Object value);

  /// No description provided for @currentHumidity.
  ///
  /// In de, this message translates to:
  /// **'Luftfeuchtigkeit: {value} %'**
  String currentHumidity(Object value);

  /// No description provided for @onlineCounters.
  ///
  /// In de, this message translates to:
  /// **'Gesamt: {total}\nGesendet: {sent}\nEmpfangen: {received}'**
  String onlineCounters(Object total, Object sent, Object received);

  /// No description provided for @byteUnits.
  ///
  /// In de, this message translates to:
  /// **'B,KB,MB,GB,TB'**
  String get byteUnits;

  /// No description provided for @noOnlineCounters.
  ///
  /// In de, this message translates to:
  /// **'Keine Online-Counter verfügbar.'**
  String get noOnlineCounters;

  /// No description provided for @noDeviceSelected.
  ///
  /// In de, this message translates to:
  /// **'Kein Gerät gewählt.'**
  String get noDeviceSelected;

  /// No description provided for @noTemperature.
  ///
  /// In de, this message translates to:
  /// **'Keine Temperatur verfügbar.'**
  String get noTemperature;

  /// No description provided for @noHumidity.
  ///
  /// In de, this message translates to:
  /// **'Keine Luftfeuchtigkeit verfügbar.'**
  String get noHumidity;

  /// No description provided for @noPower.
  ///
  /// In de, this message translates to:
  /// **'Keine Leistung verfügbar.'**
  String get noPower;

  /// No description provided for @loginRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte zuerst anmelden.'**
  String get loginRequired;

  /// No description provided for @dataSheetTitle.
  ///
  /// In de, this message translates to:
  /// **'{deviceName} - {dataType}'**
  String dataSheetTitle(Object deviceName, Object dataType);

  /// No description provided for @rangeDay.
  ///
  /// In de, this message translates to:
  /// **'24h'**
  String get rangeDay;

  /// No description provided for @rangeWeek.
  ///
  /// In de, this message translates to:
  /// **'Woche'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get rangeMonth;

  /// No description provided for @rangeTwoYears.
  ///
  /// In de, this message translates to:
  /// **'2 Jahre'**
  String get rangeTwoYears;

  /// No description provided for @wifiClientCount.
  ///
  /// In de, this message translates to:
  /// **'{count} WLAN-Clients gefunden'**
  String wifiClientCount(Object count);

  /// No description provided for @wifiClientLine.
  ///
  /// In de, this message translates to:
  /// **'{name} | IP: {ip} | MAC: {mac} | Typ: {type} | Status: {status}'**
  String wifiClientLine(
    Object name,
    Object ip,
    Object mac,
    Object type,
    Object status,
  );

  /// No description provided for @wifiClientOnline.
  ///
  /// In de, this message translates to:
  /// **'online'**
  String get wifiClientOnline;

  /// No description provided for @wifiClientOffline.
  ///
  /// In de, this message translates to:
  /// **'offline'**
  String get wifiClientOffline;

  /// No description provided for @noWifiClients.
  ///
  /// In de, this message translates to:
  /// **'Keine WLAN-Clients gefunden.'**
  String get noWifiClients;

  /// No description provided for @wifiIpLabel.
  ///
  /// In de, this message translates to:
  /// **'IP'**
  String get wifiIpLabel;

  /// No description provided for @wifiMacLabel.
  ///
  /// In de, this message translates to:
  /// **'MAC'**
  String get wifiMacLabel;

  /// No description provided for @wifiTypeLabel.
  ///
  /// In de, this message translates to:
  /// **'Typ'**
  String get wifiTypeLabel;

  /// No description provided for @wifiLastSeenLabel.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt aktiv'**
  String get wifiLastSeenLabel;

  /// No description provided for @wifiLastSeenUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get wifiLastSeenUnknown;

  /// No description provided for @wifiLastSeenNow.
  ///
  /// In de, this message translates to:
  /// **'Gerade eben'**
  String get wifiLastSeenNow;

  /// No description provided for @wifiLastSeenMinutes.
  ///
  /// In de, this message translates to:
  /// **'vor {minutes} Minuten'**
  String wifiLastSeenMinutes(Object minutes);

  /// No description provided for @wifiLastSeenHours.
  ///
  /// In de, this message translates to:
  /// **'vor {hours} Stunden'**
  String wifiLastSeenHours(Object hours);

  /// No description provided for @wifiLastSeenDays.
  ///
  /// In de, this message translates to:
  /// **'vor {days} Tagen'**
  String wifiLastSeenDays(Object days);

  /// No description provided for @wifiChannel24.
  ///
  /// In de, this message translates to:
  /// **'2,4 GHz'**
  String get wifiChannel24;

  /// No description provided for @wifiChannel5.
  ///
  /// In de, this message translates to:
  /// **'5 GHz'**
  String get wifiChannel5;

  /// No description provided for @wifiDownload.
  ///
  /// In de, this message translates to:
  /// **'Download'**
  String get wifiDownload;

  /// No description provided for @wifiUpload.
  ///
  /// In de, this message translates to:
  /// **'Upload'**
  String get wifiUpload;

  /// No description provided for @wifiTxtLabel.
  ///
  /// In de, this message translates to:
  /// **'Funkkanäle / Durchsatz'**
  String get wifiTxtLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

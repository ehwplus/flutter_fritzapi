// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'FRITZ!API Demo App';

  @override
  String get detectTitle => 'FRITZ!Box erkennen';

  @override
  String get baseUrlLabel => 'Base URL';

  @override
  String get baseUrlHelper => 'Standard: http://fritz.box';

  @override
  String get detectFound => 'FRITZ!Box gefunden.';

  @override
  String get detectSearching => 'Suche nach FRITZ!Box...';

  @override
  String get detectSearchingShort => 'Suche...';

  @override
  String get detectRetry => 'Erneut suchen';

  @override
  String detectErrorWithUrl(Object baseUrl) {
    return 'Keine FRITZ!Box unter $baseUrl gefunden.';
  }

  @override
  String detectErrorGeneric(Object error) {
    return 'Verbindungsprüfung fehlgeschlagen: $error';
  }

  @override
  String connectedStatus(Object baseUrl) {
    return 'Verbunden mit $baseUrl';
  }

  @override
  String get connectedLoggedInTitle => 'Verbunden und angemeldet';

  @override
  String sidLabel(Object sid) {
    return 'SID: $sid';
  }

  @override
  String get logoutButton => 'Logout';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get usernameLabel => 'Benutzername (optional)';

  @override
  String get loginButton => 'Login';

  @override
  String get loginButtonBusy => 'Anmelden...';

  @override
  String get loginErrorNoConnection => 'Bitte zuerst Verbindung prüfen.';

  @override
  String get loginErrorEmptyPassword => 'Passwort darf nicht leer sein.';

  @override
  String get loginErrorInvalidCreds =>
      'Login fehlgeschlagen. Bitte Benutzername/Passwort prüfen.';

  @override
  String loginErrorGeneric(Object error) {
    return 'Login fehlgeschlagen: $error';
  }

  @override
  String get devicesTitle => 'Geräte & Daten';

  @override
  String get routerLabel => 'Router';

  @override
  String get routerDeviceTitle => 'FRITZ!Box';

  @override
  String get noCapabilities => 'Keine Daten-Typen verfügbar.';

  @override
  String get temperatureLabel => 'Temperatur';

  @override
  String get humidityLabel => 'Luftfeuchtigkeit';

  @override
  String get powerLabel => 'Leistung';

  @override
  String get onlineCounterLabel => 'Online-Counter';

  @override
  String get wifiClientsLabel => 'WLAN-Clients';

  @override
  String get loadingData => 'Lade Daten...';

  @override
  String errorWithMessage(Object message) {
    return 'Fehler: $message';
  }

  @override
  String get closeButton => 'Schließen';

  @override
  String get noData => 'Keine Daten';

  @override
  String get historyTitle => 'Historie';

  @override
  String get historyEnergyMissing =>
      'Keine historischen Energiedaten verfügbar.';

  @override
  String historyEnergy(Object dayWh, Object monthWh, Object yearWh) {
    return 'Heute: $dayWh Wh\nMonat: $monthWh Wh\nJahr: $yearWh Wh';
  }

  @override
  String historyPowerEntry(Object range, Object value) {
    return '$range: $value Wh';
  }

  @override
  String historySensorEntry(Object range, Object value) {
    return '$range: $value';
  }

  @override
  String currentPower(Object value) {
    return 'Leistung: $value W';
  }

  @override
  String currentTemperature(Object value) {
    return 'Temperatur: $value °C';
  }

  @override
  String currentHumidity(Object value) {
    return 'Luftfeuchtigkeit: $value %';
  }

  @override
  String onlineCounters(Object total, Object sent, Object received) {
    return 'Gesamt: $total\nGesendet: $sent\nEmpfangen: $received';
  }

  @override
  String get byteUnits => 'B,KB,MB,GB,TB';

  @override
  String get noOnlineCounters => 'Keine Online-Counter verfügbar.';

  @override
  String get noDeviceSelected => 'Kein Gerät gewählt.';

  @override
  String get noTemperature => 'Keine Temperatur verfügbar.';

  @override
  String get noHumidity => 'Keine Luftfeuchtigkeit verfügbar.';

  @override
  String get noPower => 'Keine Leistung verfügbar.';

  @override
  String get loginRequired => 'Bitte zuerst anmelden.';

  @override
  String dataSheetTitle(Object deviceName, Object dataType) {
    return '$deviceName - $dataType';
  }

  @override
  String get rangeDay => '24h';

  @override
  String get rangeWeek => 'Woche';

  @override
  String get rangeMonth => 'Monat';

  @override
  String get rangeTwoYears => '2 Jahre';

  @override
  String wifiClientCount(Object count) {
    return '$count WLAN-Clients gefunden';
  }

  @override
  String wifiClientLine(
    Object name,
    Object ip,
    Object mac,
    Object type,
    Object status,
  ) {
    return '$name | IP: $ip | MAC: $mac | Typ: $type | Status: $status';
  }

  @override
  String get wifiClientOnline => 'online';

  @override
  String get wifiClientOffline => 'offline';

  @override
  String get noWifiClients => 'Keine WLAN-Clients gefunden.';

  @override
  String get wifiIpLabel => 'IP';

  @override
  String get wifiMacLabel => 'MAC';

  @override
  String get wifiTypeLabel => 'Typ';

  @override
  String get wifiLastSeenLabel => 'Zuletzt aktiv';

  @override
  String get wifiLastSeenUnknown => 'Unbekannt';

  @override
  String get wifiLastSeenNow => 'Gerade eben';

  @override
  String wifiLastSeenMinutes(Object minutes) {
    return 'vor $minutes Minuten';
  }

  @override
  String wifiLastSeenHours(Object hours) {
    return 'vor $hours Stunden';
  }

  @override
  String wifiLastSeenDays(Object days) {
    return 'vor $days Tagen';
  }

  @override
  String get wifiChannel24 => '2,4 GHz';

  @override
  String get wifiChannel5 => '5 GHz';

  @override
  String get wifiDownload => 'Download';

  @override
  String get wifiUpload => 'Upload';

  @override
  String get wifiTxtLabel => 'Funkkanäle / Durchsatz';

  @override
  String get copySidTooltip => 'SID kopieren';

  @override
  String get sidCopied => 'SID in Zwischenablage kopiert';

  @override
  String get copyDeviceIdTooltip => 'Device-ID kopieren';

  @override
  String deviceIdCopied(Object id) {
    return 'Device-ID $id kopiert';
  }
}

import 'package:example/src/custom_fritz_api_client.dart';
import 'package:example/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_fritzapi/flutter_fritzapi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('de'),
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CustomFritzApiClient? _fritzApiClient;

  final TextEditingController _baseUrlController = TextEditingController(text: 'http://fritz.box');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  SharedPreferences? _prefs;
  bool _detecting = false;
  bool _connected = false;
  bool _loggingIn = false;
  String? _detectError;
  String? _loginError;
  String? _sessionId;
  List<Device> _devices = <Device>[];
  final Map<String, _DataType> _selectedCapabilities = <String, _DataType>{};

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String baseUrl = prefs.getString('baseUrl') ?? 'http://fritz.box';
    final String username = prefs.getString('username') ?? '';
    final String password = prefs.getString('password') ?? '';
    setState(() {
      _prefs = prefs;
      _baseUrlController.text = baseUrl;
      _usernameController.text = username;
      _passwordController.text = password;
    });
    _rebuildClient();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _autoDetect();
      }
    });
  }

  void _rebuildClient() {
    _fritzApiClient = CustomFritzApiClient(baseUrl: _currentBaseUrl);
    setState(() {
      _sessionId = null;
      _devices = <Device>[];
      _connected = false;
    });
  }

  String get _currentBaseUrl {
    final String trimmed = _baseUrlController.text.trim();
    return trimmed.isEmpty ? 'http://fritz.box' : trimmed;
  }

  Future<void> _autoDetect() async {
    final CustomFritzApiClient? client = _fritzApiClient;
    if (client == null) {
      return;
    }
    setState(() {
      _detecting = true;
      _detectError = null;
      _connected = false;
    });
    try {
      final bool isConnected = await client.isConnectedWithFritzBox();
      if (!mounted) {
        return;
      }
      setState(() {
        _connected = isConnected;
        _detectError = isConnected ? null : l10n.detectErrorWithUrl(_currentBaseUrl);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _detectError = l10n.detectErrorGeneric('$error');
        _connected = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _detecting = false;
        });
      }
    }
  }

  Future<void> _login() async {
    final CustomFritzApiClient? client = _fritzApiClient;
    if (client == null || !_connected) {
      setState(() {
        _loginError = l10n.loginErrorNoConnection;
      });
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _loginError = l10n.loginErrorEmptyPassword;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loggingIn = true;
      _loginError = null;
    });
    try {
      final String? sid = await client.getSessionId(
        username: _usernameController.text.isEmpty ? null : _usernameController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      if (sid == null || sid.isEmpty) {
        setState(() {
          _loginError = l10n.loginErrorInvalidCreds;
          _sessionId = null;
        });
        return;
      }
      final Devices devices = await client.getDevices();
      await _persistPrefs();
      setState(() {
        _sessionId = sid;
        _devices = devices.devices;
        _loginError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loginError = l10n.loginErrorGeneric('$error');
        _sessionId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loggingIn = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _sessionId = null;
      _devices = <Device>[];
      _selectedCapabilities.clear();
      _loginError = null;
    });
  }

  Future<void> _persistPrefs() async {
    await _prefs?.setString('baseUrl', _currentBaseUrl);
    await _prefs?.setString('username', _usernameController.text);
    await _prefs?.setString('password', _passwordController.text);
  }

  List<_DataType> _capabilitiesForDevice(Device? device, {required bool isRouter}) {
    if (isRouter) {
      return const <_DataType>[/*_DataType.onlineCounter, */ _DataType.wifiClients];
    }
    if (device == null) {
      return const <_DataType>[];
    }
    final List<_DataType> caps = <_DataType>[];
    if (device.capabilities.contains(DeviceCapability.temperature)) {
      caps.add(_DataType.temperature);
    }
    if (device.capabilities.contains(DeviceCapability.humidity)) {
      caps.add(_DataType.humidity);
    }
    if (device.capabilities.contains(DeviceCapability.energy)) {
      caps.add(_DataType.power);
    }
    return caps;
  }

  Future<void> _onCapabilitySelected({
    required String deviceKey,
    required _DataType type,
    Device? device,
    required bool isRouter,
  }) async {
    setState(() {
      _selectedCapabilities[deviceKey] = type;
    });
    await _showDataSheet(
      deviceName: device?.displayName ?? l10n.routerDeviceTitle,
      device: device,
      type: type,
      isRouter: isRouter,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedCapabilities.remove(deviceKey);
    });
  }

  Future<void> _showDataSheet({
    required String deviceName,
    Device? device,
    required _DataType type,
    required bool isRouter,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<_DataPayload>(
            future: _loadData(device: device, type: type, isRouter: isRouter),
            builder: (BuildContext context, AsyncSnapshot<_DataPayload> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.dataSheetTitle(deviceName, type.label(l10n)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(l10n.loadingData),
                  ],
                );
              }
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.dataSheetTitle(deviceName, type.label(l10n)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.errorWithMessage('${snapshot.error}'), style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.closeButton)),
                    ),
                  ],
                );
              }
              final _DataPayload? data = snapshot.data;
              if (type == _DataType.wifiClients && data?.wifiClients != null) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.dataSheetTitle(deviceName, type.label(l10n)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(data!.current),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 420,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          final WifiClient client = data.wifiClients![index];
                          return _buildWifiClientTile(client);
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: data.wifiClients!.length,
                      ),
                    ),
                    if (data.raw != null) ...<Widget>[const SizedBox(height: 12), _buildRawSection(data.raw!)],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.closeButton)),
                    ),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.dataSheetTitle(deviceName, type.label(l10n)),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(data?.current ?? l10n.noData),
                  if (data?.history != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(l10n.historyTitle, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(data!.history!),
                  ],
                  if (data?.raw != null) ...<Widget>[const SizedBox(height: 12), _buildRawSection(data!.raw!)],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.closeButton)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<Device?> _fetchDeviceById(int id) async {
    final CustomFritzApiClient? client = _fritzApiClient;
    if (client == null) {
      return null;
    }
    final Devices devices = await client.getDevices();
    for (final Device device in devices.devices) {
      if (device.id == id) {
        return device;
      }
    }
    return null;
  }

  Future<_DataPayload> _loadData({Device? device, required _DataType type, required bool isRouter}) async {
    final CustomFritzApiClient? client = _fritzApiClient;
    if (client == null || _sessionId == null) {
      throw StateError(l10n.loginRequired);
    }
    switch (type) {
      /*case _DataType.onlineCounter:
        final NetworkCounters? counters = await client.getOnlineCounters();
        if (counters == null) {
          throw StateError(l10n.noOnlineCounters);
        }
        return _DataPayload(
          current: l10n.onlineCounters(
            _formatBytes(counters.totalBytes),
            _formatBytes(counters.bytesSent),
            _formatBytes(counters.bytesReceived),
          ),
          raw: _stringifyRaw(counters.raw),
        );*/
      case _DataType.temperature:
        if (device == null) {
          throw StateError(l10n.noDeviceSelected);
        }
        final Device effective = (await _fetchDeviceById(device.id)) ?? device;
        final double? value = effective.temperatureCelsius;
        if (value == null) {
          throw StateError(l10n.noTemperature);
        }
        final Map<HistoryRange, SensorHistory> histories = await client.getTemperatureHistory(
          effective.id,
          ranges: HistoryRange.values,
        );
        final String historyText = _formatSensorHistory(histories, unit: '°C');
        return _DataPayload(
          current: l10n.currentTemperature(value.toStringAsFixed(1)),
          history: historyText.isEmpty ? null : historyText,
          raw: _stringifyRaw(histories),
        );
      case _DataType.humidity:
        if (device == null) {
          throw StateError(l10n.noDeviceSelected);
        }
        final Device effective = (await _fetchDeviceById(device.id)) ?? device;
        final double? value = effective.humidityPercent;
        if (value == null) {
          throw StateError(l10n.noHumidity);
        }
        final Map<HistoryRange, SensorHistory> histories = await client.getHumidityHistory(
          effective.id,
          ranges: HistoryRange.values,
        );
        final String historyText = _formatSensorHistory(histories, unit: '%');
        return _DataPayload(
          current: l10n.currentHumidity(value.toStringAsFixed(1)),
          history: historyText.isEmpty ? null : historyText,
          raw: _stringifyRaw(histories),
        );
      case _DataType.power:
        if (device == null) {
          throw StateError(l10n.noDeviceSelected);
        }
        final Device effective = (await _fetchDeviceById(device.id)) ?? device;
        final double? value = effective.powerWatt;
        if (value == null) {
          throw StateError(l10n.noPower);
        }
        final PowerHistory? history = await client.getPowerHistory(effective.id, ranges: HistoryRange.values);
        final String historyText = _formatPowerHistory(history);
        return _DataPayload(
          current: l10n.currentPower(value.toStringAsFixed(1)),
          history: historyText.isEmpty ? l10n.historyEnergyMissing : historyText,
          raw: _stringifyRaw(history),
        );
      case _DataType.wifiClients:
        final List<WifiClient> clients = await client.getWifiClients();
        if (clients.isEmpty) {
          throw StateError(l10n.noWifiClients);
        }
        return _DataPayload(current: l10n.wifiClientCount(clients.length.toString()), wifiClients: clients);
    }
  }

  String _formatSensorHistory(Map<HistoryRange, SensorHistory> histories, {required String unit}) {
    if (histories.isEmpty) {
      return '';
    }
    final StringBuffer sb = StringBuffer();
    histories.forEach((HistoryRange range, SensorHistory history) {
      final double? avg = history.average;
      if (avg != null) {
        sb.writeln(l10n.historySensorEntry(_rangeLabel(range), '${avg.toStringAsFixed(1)} $unit'));
      }
    });
    return sb.toString().trim();
  }

  String _formatPowerHistory(PowerHistory? history) {
    if (history == null) {
      return '';
    }
    final StringBuffer sb = StringBuffer();
    if (history.day != null) {
      sb.writeln(l10n.historyPowerEntry(_rangeLabel(HistoryRange.day), history.day!.sumDay.toString()));
    }
    if (history.week != null) {
      final int weekTotal = history.week!.energyStat.values.fold(0, (int a, int b) => a + b);
      sb.writeln(l10n.historyPowerEntry(_rangeLabel(HistoryRange.week), weekTotal.toString()));
    }
    if (history.month != null) {
      sb.writeln(l10n.historyPowerEntry(_rangeLabel(HistoryRange.month), history.month!.sumMonth.toString()));
    }
    if (history.twoYears != null) {
      sb.writeln(l10n.historyPowerEntry(_rangeLabel(HistoryRange.twoYears), history.twoYears!.sumYear.toString()));
    }
    return sb.toString().trim();
  }

  String _rangeLabel(HistoryRange range) {
    switch (range) {
      case HistoryRange.day:
        return l10n.rangeDay;
      case HistoryRange.week:
        return l10n.rangeWeek;
      case HistoryRange.month:
        return l10n.rangeMonth;
      case HistoryRange.twoYears:
        return l10n.rangeTwoYears;
    }
  }

  Widget _buildWifiClientTile(WifiClient client) {
    final String lastSeen = _formatLastSeen(client.lastSeen);
    final String channel2_4 = client.radioChannel2_4 != null ? client.radioChannel2_4! : '';
    final String channel5 = client.radioChannel5 != null ? client.radioChannel5! : '';
    final String channel6 = client.radioChannel6 != null ? client.radioChannel6! : '';
    final String txtInfo =
        '${channel2_4.isEmpty ? '' : channel2_4} ${channel5.isEmpty ? '' : '${channel2_4.isNotEmpty ? ', ' : ''}$channel5'} ${channel6.isEmpty ? '' : '${channel2_4.isNotEmpty || channel5.isNotEmpty ? ', ' : ''}$channel6'}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(client.deviceType.icon, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(child: Text(client.name, style: Theme.of(context).textTheme.titleMedium)),
                if (client.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(l10n.wifiClientOnline, style: TextStyle(color: Colors.green)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: <Widget>[
                Text('${l10n.wifiIpLabel}: ${client.ip ?? '-'}'),
                Text('${l10n.wifiMacLabel}: ${client.mac ?? '-'}'),
                Text('${l10n.wifiLastSeenLabel}: $lastSeen'),
              ],
            ),
            const SizedBox(height: 6),
            Text('${l10n.wifiTxtLabel}: $txtInfo'),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime? time) {
    if (time == null) {
      return l10n.wifiLastSeenUnknown;
    }
    final Duration diff = DateTime.now().toUtc().difference(time);
    if (diff.inMinutes < 1) {
      return l10n.wifiLastSeenNow;
    }
    if (diff.inHours < 1) {
      return l10n.wifiLastSeenMinutes(diff.inMinutes.toString());
    }
    if (diff.inDays < 1) {
      return l10n.wifiLastSeenHours(diff.inHours.toString());
    }
    return l10n.wifiLastSeenDays(diff.inDays.toString());
  }

  String _formatBytes(int bytes) {
    final List<String> units = l10n.byteUnits.split(',');
    double value = bytes.toDouble();
    int unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unitIndex]}';
  }

  String _stringifyRaw(dynamic raw) {
    try {
      return const JsonEncoder.withIndent('  ').convert(raw);
    } catch (_) {
      return raw?.toString() ?? '';
    }
  }

  Widget _buildRawSection(String raw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(l10n.rawTitle, style: Theme.of(context).textTheme.titleSmall),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: l10n.copyRawTooltip,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: raw));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.rawCopied)));
              },
            ),
          ],
        ),
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            child: Text(raw, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard() {
    if (_connected) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(l10n.connectedStatus(_currentBaseUrl)),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.detectTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(labelText: l10n.baseUrlLabel, helperText: l10n.baseUrlHelper),
              onChanged: (_) => _persistPrefs(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  _connected ? Icons.check_circle : Icons.search,
                  color: _connected ? Colors.green : Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_connected ? l10n.detectFound : l10n.detectSearching)),
                TextButton(
                  onPressed: _detecting
                      ? null
                      : () {
                          _rebuildClient();
                          _autoDetect();
                        },
                  child: _detecting ? Text(l10n.detectSearchingShort) : Text(l10n.detectRetry),
                ),
              ],
            ),
            if (_detectError != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_detectError!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsCard() {
    if (_sessionId != null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.loginTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              enabled: _connected,
              decoration: InputDecoration(labelText: l10n.passwordLabel),
              obscureText: true,
              focusNode: _passwordFocus,
              onChanged: (_) => _persistPrefs(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              enabled: _connected,
              decoration: InputDecoration(labelText: l10n.usernameLabel),
              focusNode: _usernameFocus,
              onChanged: (_) => _persistPrefs(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: !_connected || _loggingIn ? null : _login,
                  child: _loggingIn ? Text(l10n.loginButtonBusy) : Text(l10n.loginButton),
                ),
              ],
            ),
            if (_loginError != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_loginError!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInCard() {
    final String sid = _sessionId ?? '';
    final String sidShort = sid.isNotEmpty && sid.length > 6 ? '${sid.substring(0, 6)}...' : sid;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lock_open, color: Colors.green),
        title: Text(l10n.connectedLoggedInTitle),
        subtitle: Text(
          l10n.connectedStatus(_currentBaseUrl) + (sidShort.isNotEmpty ? '\n${l10n.sidLabel(sidShort)}' : ''),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: l10n.copySidTooltip,
              icon: const Icon(Icons.copy),
              onPressed: sid.isEmpty
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: sid));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.sidCopied)));
                    },
            ),
            TextButton(onPressed: _logout, child: Text(l10n.logoutButton)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_sessionId == null) {
      return const SizedBox.shrink();
    }
    final List<Widget> deviceCards = <Widget>[];
    deviceCards.add(
      _buildDeviceCard(
        deviceKey: 'router',
        title: l10n.routerDeviceTitle,
        subtitle: _currentBaseUrl,
        device: null,
        isRouter: true,
        l10n: l10n,
      ),
    );
    for (final Device device in _devices) {
      deviceCards.add(
        _buildDeviceCard(
          deviceKey: 'device-${device.id}',
          title: device.displayName,
          subtitle: device.model,
          device: device,
          isRouter: false,
          l10n: l10n,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.devicesTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...deviceCards,
      ],
    );
  }

  Widget _buildDeviceCard({
    required String deviceKey,
    required String title,
    required String subtitle,
    required Device? device,
    required bool isRouter,
    required AppLocalizations l10n,
  }) {
    final List<_DataType> caps = _capabilitiesForDevice(device, isRouter: isRouter);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    isRouter ? l10n.routerLabel : device?.category.name ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!isRouter && device != null)
                    IconButton(
                      tooltip: l10n.copyDeviceIdTooltip,
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: device.id.toString()));
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l10n.deviceIdCopied(device.id.toString()))));
                      },
                    ),
                ],
              ),
            ),
            if (caps.isEmpty)
              Text(l10n.noCapabilities)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: caps
                    .map(
                      (_DataType type) => ChoiceChip(
                        label: Text(type.label(l10n)),
                        avatar: Icon(type.icon, size: 18),
                        selected: _selectedCapabilities[deviceKey] == type,
                        onSelected: (_) =>
                            _onCapabilitySelected(deviceKey: deviceKey, type: type, device: device, isRouter: isRouter),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = l10n;
    final List<Widget> sections = <Widget>[];
    if (_sessionId != null) {
      sections.add(_buildLoggedInCard());
    } else {
      sections
        ..add(_buildConnectionCard())
        ..add(_buildCredentialsCard());
    }
    sections.add(const SizedBox(height: 12));
    sections.add(_buildDeviceList());

    return Scaffold(
      appBar: AppBar(title: Text(loc.appTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections),
        ),
      ),
    );
  }
}

enum _DataType { temperature, humidity, power, wifiClients } // onlineCounter

extension on _DataType {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _DataType.temperature:
        return l10n.temperatureLabel;
      case _DataType.humidity:
        return l10n.humidityLabel;
      case _DataType.power:
        return l10n.powerLabel;
      // case _DataType.onlineCounter:
      //   return l10n.onlineCounterLabel;
      case _DataType.wifiClients:
        return l10n.wifiClientsLabel;
    }
  }

  IconData get icon {
    switch (this) {
      case _DataType.temperature:
        return Icons.thermostat;
      case _DataType.humidity:
        return Icons.water_drop;
      case _DataType.power:
        return Icons.bolt;
      // case _DataType.onlineCounter:
      //   return Icons.network_check;
      case _DataType.wifiClients:
        return Icons.wifi;
    }
  }
}

class _DataPayload {
  const _DataPayload({required this.current, this.history, this.wifiClients, this.raw});

  final String current;
  final String? history;
  final List<WifiClient>? wifiClients;
  final String? raw;
}

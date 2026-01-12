import 'package:example/l10n/generated/app_localizations.dart';
import 'package:example/custom_fritz_api_client.dart';

import 'package:flutter/material.dart';
import 'package:flutter_fritzapi/flutter_fritzapi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('de'),
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,
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

  AppLocalizations get l10n => AppLocalizations.of(context)!;

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
      return const <_DataType>[_DataType.onlineCounter];
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.dataSheetTitle(deviceName, type.label(l10n)),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(snapshot.data?.current ?? l10n.noData),
                  if (snapshot.data?.history != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(l10n.historyTitle, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(snapshot.data!.history!),
                  ],
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
      case _DataType.onlineCounter:
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
        );
      case _DataType.temperature:
        if (device == null) {
          throw StateError(l10n.noDeviceSelected);
        }
        final Device effective = (await _fetchDeviceById(device.id)) ?? device;
        final double? value = effective.temperatureCelsius;
        if (value == null) {
          throw StateError(l10n.noTemperature);
        }
        return _DataPayload(current: l10n.currentTemperature(value.toStringAsFixed(1)));
      case _DataType.humidity:
        if (device == null) {
          throw StateError(l10n.noDeviceSelected);
        }
        final Device effective = (await _fetchDeviceById(device.id)) ?? device;
        final double? value = effective.humidityPercent;
        if (value == null) {
          throw StateError(l10n.noHumidity);
        }
        return _DataPayload(current: l10n.currentHumidity(value.toStringAsFixed(1)));
      case _DataType.power:
        if (device == null) {
          throw StateError(l10n.noDeviceSelected);
        }
        final Device effective = (await _fetchDeviceById(device.id)) ?? device;
        final double? value = effective.powerWatt;
        if (value == null) {
          throw StateError(l10n.noPower);
        }
        final EnergyStats? stats = await client.getEnergyStats(
          command: HomeAutoQueryCommand.EnergyStats_24h,
          deviceId: effective.id,
        );
        final String history = stats == null
            ? l10n.historyEnergyMissing
            : l10n.historyEnergy(stats.sumDay.toString(), stats.sumMonth.toString(), stats.sumYear.toString());
        return _DataPayload(current: l10n.currentPower(value.toStringAsFixed(1)), history: history);
    }
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
        trailing: TextButton(onPressed: _logout, child: Text(l10n.logoutButton)),
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
              trailing: Text(
                isRouter ? l10n.routerLabel : device?.category.name ?? '',
                style: Theme.of(context).textTheme.bodySmall,
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

enum _DataType { temperature, humidity, power, onlineCounter }

extension on _DataType {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _DataType.temperature:
        return l10n.temperatureLabel;
      case _DataType.humidity:
        return l10n.humidityLabel;
      case _DataType.power:
        return l10n.powerLabel;
      case _DataType.onlineCounter:
        return l10n.onlineCounterLabel;
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
      case _DataType.onlineCounter:
        return Icons.network_check;
    }
  }
}

class _DataPayload {
  const _DataPayload({required this.current, this.history});

  final String current;
  final String? history;
}

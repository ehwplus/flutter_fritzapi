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
    const title = 'FRITZ!API Demo App';
    return MaterialApp(
      title: title,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: title),
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
  CustomFritzApiClient? _fritzApiClient;

  final TextEditingController _baseUrlController = TextEditingController(
    text: 'http://fritz.box',
  );
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
    await _autoDetect();
  }

  void _rebuildClient() {
    _fritzApiClient = CustomFritzApiClient(baseUrl: _currentBaseUrl);
    setState(() {
      _sessionId = null;
      _devices = <Device>[];
      _connected = false;
    });
  }

  Future<void> _showBaseUrlDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _baseUrlController.text,
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Base URL anpassen'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              helperText: 'z.B. http://fritz.box',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      _baseUrlController.text = result.isEmpty ? 'http://fritz.box' : result;
      await _persistPrefs();
      _rebuildClient();
      _autoDetect();
    }
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
        _detectError = isConnected
            ? null
            : 'Keine FRITZ!Box unter $_currentBaseUrl gefunden.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _detectError = 'Verbindungsprüfung fehlgeschlagen: $error';
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
        _loginError = 'Bitte zuerst Verbindung prüfen.';
      });
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _loginError = 'Passwort darf nicht leer sein.';
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
        username: _usernameController.text.isEmpty
            ? null
            : _usernameController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      if (sid == null || sid.isEmpty) {
        setState(() {
          _loginError =
              'Login fehlgeschlagen. Bitte Benutzername/Passwort prüfen.';
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
        _loginError = 'Login fehlgeschlagen: $error';
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

  List<_DataType> _capabilitiesForDevice(
    Device? device, {
    required bool isRouter,
  }) {
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
      deviceName: device?.displayName ?? 'FRITZ!Box',
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
          child: FutureBuilder<String>(
            future: _loadData(device: device, type: type, isRouter: isRouter),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$deviceName – ${type.label}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Lade Daten...'),
                  ],
                );
              }
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$deviceName – ${type.label}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fehler: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Schließen'),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$deviceName – ${type.label}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(snapshot.data ?? 'Keine Daten'),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Schließen'),
                    ),
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

  Future<String> _loadData({
    Device? device,
    required _DataType type,
    required bool isRouter,
  }) async {
    final CustomFritzApiClient? client = _fritzApiClient;
    if (client == null || _sessionId == null) {
      throw StateError('Bitte zuerst anmelden.');
    }
    switch (type) {
      case _DataType.onlineCounter:
        final NetworkCounters? counters = await client.getOnlineCounters();
        if (counters == null) {
          throw StateError('Keine Online-Counter verfügbar.');
        }
        return 'Gesamt: ${_formatBytes(counters.totalBytes)}\nGesendet: ${_formatBytes(counters.bytesSent)}\nEmpfangen: ${_formatBytes(counters.bytesReceived)}';
      case _DataType.temperature:
        if (device == null) {
          throw StateError('Kein Gerät gewählt.');
        }
        final Device effective = (await _fetchDeviceById(device.id)) ?? device;
        final double? value = effective.temperatureCelsius;
        if (value == null) {
          throw StateError('Keine Temperatur verfügbar.');
        }
        return 'Temperatur: ${value.toStringAsFixed(1)} °C';
      case _DataType.humidity:
        if (device == null) {
          throw StateError('Kein Gerät gewählt.');
        }
        final Device effective = (await _fetchDeviceById(device.id)) ?? device;
        final double? value = effective.humidityPercent;
        if (value == null) {
          throw StateError('Keine Luftfeuchtigkeit verfügbar.');
        }
        return 'Luftfeuchtigkeit: ${value.toStringAsFixed(1)} %';
      case _DataType.power:
        if (device == null) {
          throw StateError('Kein Gerät gewählt.');
        }
        final Device effective = (await _fetchDeviceById(device.id)) ?? device;
        final double? value = effective.powerWatt;
        if (value == null) {
          throw StateError('Keine Leistung verfügbar.');
        }
        return 'Leistung: ${value.toStringAsFixed(1)} W';
    }
  }

  String _formatBytes(int bytes) {
    const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
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
          title: Text('Verbunden mit $_currentBaseUrl'),
          trailing: Wrap(
            spacing: 8,
            children: <Widget>[
              TextButton(
                onPressed: () => _showBaseUrlDialog(),
                child: const Text('Base URL ändern'),
              ),
              TextButton(
                onPressed: _detecting
                    ? null
                    : () {
                        _rebuildClient();
                        _autoDetect();
                      },
                child: _detecting
                    ? const Text('Suche...')
                    : const Text('Neu suchen'),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '1. FRITZ!Box erkennen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                helperText: 'Standard: http://fritz.box',
              ),
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
                Expanded(
                  child: Text(
                    _connected
                        ? 'FRITZ!Box gefunden.'
                        : 'Suche nach FRITZ!Box...',
                  ),
                ),
                TextButton(
                  onPressed: _detecting
                      ? null
                      : () {
                          _rebuildClient();
                          _autoDetect();
                        },
                  child: _detecting
                      ? const Text('Suche...')
                      : const Text('Retry'),
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
      return Card(
        child: ListTile(
          leading: const Icon(Icons.lock_open, color: Colors.green),
          title: const Text('Angemeldet'),
          subtitle: Text(
            'SID: ${_sessionId!.substring(0, _sessionId!.length > 6 ? 6 : _sessionId!.length)}...',
          ),
          trailing: TextButton(onPressed: _logout, child: const Text('Logout')),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('2. Anmelden', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              enabled: _connected,
              decoration: const InputDecoration(labelText: 'Passwort'),
              obscureText: true,
              focusNode: _passwordFocus,
              onChanged: (_) => _persistPrefs(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              enabled: _connected,
              decoration: const InputDecoration(
                labelText: 'Benutzername (optional)',
              ),
              focusNode: _usernameFocus,
              onChanged: (_) => _persistPrefs(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: !_connected || _loggingIn ? null : _login,
                  child: _loggingIn
                      ? const Text('Anmelden...')
                      : const Text('Login'),
                ),
                const SizedBox(width: 12),
                if (_sessionId != null)
                  const Text(
                    'Angemeldet',
                    style: TextStyle(color: Colors.green),
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

  Widget _buildDeviceList() {
    if (_sessionId == null) {
      return const SizedBox.shrink();
    }
    final List<Widget> deviceCards = <Widget>[];
    deviceCards.add(
      _buildDeviceCard(
        deviceKey: 'router',
        title: 'FRITZ!Box',
        subtitle: _currentBaseUrl,
        device: null,
        isRouter: true,
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
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '3. Geräte & Daten',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
  }) {
    final List<_DataType> caps = _capabilitiesForDevice(
      device,
      isRouter: isRouter,
    );
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
                isRouter ? 'Router' : device?.category.name ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (caps.isEmpty)
              const Text('Keine Daten-Typen verfügbar.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: caps
                    .map(
                      (_DataType type) => ChoiceChip(
                        label: Text(type.label),
                        avatar: Icon(type.icon, size: 18),
                        selected: _selectedCapabilities[deviceKey] == type,
                        onSelected: (_) => _onCapabilitySelected(
                          deviceKey: deviceKey,
                          type: type,
                          device: device,
                          isRouter: isRouter,
                        ),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildConnectionCard(),
              _buildCredentialsCard(),
              const SizedBox(height: 12),
              _buildDeviceList(),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DataType { temperature, humidity, power, onlineCounter }

extension on _DataType {
  String get label {
    switch (this) {
      case _DataType.temperature:
        return 'Temperature';
      case _DataType.humidity:
        return 'Humidity';
      case _DataType.power:
        return 'Power';
      case _DataType.onlineCounter:
        return 'Online counter';
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

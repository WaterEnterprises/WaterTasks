import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:audio_service/audio_service.dart';
import 'package:phone_state/phone_state.dart';

List<String> extractPhoneNumbers(String text) {
  final result = <String>[];
  final lines = text.split(RegExp(r'[\r\n]+'));
  final phoneRegex = RegExp(r'\+?[\d\s\-\(\)]{10,}');
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    for (final match in phoneRegex.allMatches(line)) {
      final src = match.group(0)!;
      String digits = src.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) continue;
      final hadPlus = src.startsWith('+');
      if (!hadPlus) {
        // Strip leading zeros (Brazilian trunk prefix)
        digits = digits.replaceFirst(RegExp(r'^0+'), '');
        if (digits.length < 10) continue;
      }
      String? international;
      if (hadPlus && digits.length >= 10 && digits.length <= 15) {
        international = '+$digits';
      } else if (digits.length == 10 || digits.length == 11) {
        if (digits.length == 10 && (int.tryParse(digits.substring(2, 3)) ?? 0) >= 6) {
          digits = '${digits.substring(0, 2)}9${digits.substring(2)}';
        }
        international = '+55$digits';
      } else if (digits.length == 12 && digits.startsWith('55')) {
        international = '+$digits';
      } else if (digits.length == 13 && digits.startsWith('55')) {
        international = '+$digits';
      }
      if (international != null) {
        if (!hadPlus) {
          try {
            final parsed = PhoneNumber.parse(international!);
            if (parsed.isValid()) {
              international = '+${parsed.countryCode}${parsed.nsn}';
            }
          } catch (_) {}
        }
        if (international!.length >= 12 && international!.length <= 16) {
          result.add(international!);
        }
      }
    }
  }
  return result;
}

// Use a nullable handler to avoid "Late Initialization" errors
MyCallAudioHandler? _handler;

Future<void> main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Start the UI IMMEDIATELY to avoid the blank screen
  runApp(const CallCenterApp());

  // 3. Initialize background service after UI starts
  try {
    _handler = await AudioService.init(
      builder: () => MyCallAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.jv.calling.channel.audio',
        androidNotificationChannelName: 'Call Center Service',
        // Combined these to satisfy library rules and keep app alive
        androidNotificationOngoing: true, 
        androidStopForegroundOnPause: true, 
      ),
    );
  } catch (e) {
    debugPrint("AudioService failed to start: $e");
  }
}

class MyCallAudioHandler extends BaseAudioHandler {
  PhoneStateStatus _currentPhoneStatus = PhoneStateStatus.NOTHING;

  MyCallAudioHandler() {
    // Background listener for phone state
    PhoneState.stream.listen((event) {
      _currentPhoneStatus = event.status;
      if (_currentPhoneStatus == PhoneStateStatus.NOTHING || 
          _currentPhoneStatus == PhoneStateStatus.CALL_ENDED) {
        _takeControl();
      }
    });
    _takeControl();
  }

  void _takeControl() {
    playbackState.add(PlaybackState(
      controls: [MediaControl.play, MediaControl.pause],
      systemActions: {MediaAction.play, MediaAction.pause, MediaAction.playPause},
      processingState: AudioProcessingState.ready,
      playing: true, 
    ));
  }

  @override
  Future<void> play() => _checkAndDial();
  @override
  Future<void> pause() => _checkAndDial();
  @override
  Future<void> stop() => _checkAndDial();

  Future<void> _checkAndDial() async {
    if (_currentPhoneStatus != PhoneStateStatus.NOTHING && 
        _currentPhoneStatus != PhoneStateStatus.CALL_ENDED) return;
    await _makeBackgroundCall();
  }

  Future<void> _makeBackgroundCall() async {
    if (!await Permission.phone.isGranted) return;
    final dbPath = await getDatabasesPath();
    final database = await openDatabase(p.join(dbPath, 'callcenter.db'));
    final List<Map<String, dynamic>> maps = await database.query(
      'numbers', where: 'wasCalled = ?', whereArgs: [0], limit: 1,
    );
    if (maps.isNotEmpty) {
      final id = maps.first['id'] as int;
      final number = maps.first['number'] as String;
      if (await FlutterPhoneDirectCaller.callNumber(number) ?? false) {
        await database.update('numbers', {'wasCalled': 1}, where: 'id = ?', whereArgs: [id]);
      }
    }
    await database.close();
    _takeControl();
  }
}

class CallCenterApp extends StatelessWidget {
  const CallCenterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Center Auto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const CallCenterHome(),
    );
  }
}

class PhoneNumberModel {
  final int? id;
  final String number;
  final bool wasCalled;
  PhoneNumberModel({this.id, required this.number, this.wasCalled = false});
  factory PhoneNumberModel.fromMap(Map<String, dynamic> map) => PhoneNumberModel(
    id: map['id'], number: map['number'], wasCalled: map['wasCalled'] == 1,
  );
}

class CallCenterHome extends StatefulWidget {
  const CallCenterHome({super.key});
  @override
  State<CallCenterHome> createState() => _CallCenterHomeState();
}

class _CallCenterHomeState extends State<CallCenterHome> with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  List<PhoneNumberModel> _numbers = [];
  Map<String, int> _stats = {'total': 0, 'called': 0, 'remaining': 0};
  PhoneStateStatus _uiPhoneStatus = PhoneStateStatus.NOTHING;
  StreamSubscription? _phoneSub;
  bool _isLoading = false;
  bool _autoDialActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _phoneSub = PhoneState.stream.listen((event) {
      if (!mounted) return;
      setState(() => _uiPhoneStatus = event.status);
      if (_autoDialActive && (event.status == PhoneStateStatus.NOTHING || event.status == PhoneStateStatus.CALL_ENDED)) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _autoDialActive) _autoDialNext();
        });
      }
    });
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(p.join(dbPath, 'callcenter.db'), version: 1, onCreate: (db, v) async {
        await db.execute('CREATE TABLE numbers (id INTEGER PRIMARY KEY AUTOINCREMENT, number TEXT UNIQUE, wasCalled INTEGER)');
      });
      final List<Map<String, dynamic>> res = await db.query('numbers');
      final total = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM numbers')) ?? 0;
      final called = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM numbers WHERE wasCalled = 1')) ?? 0;
      setState(() {
        _numbers = res.map((m) => PhoneNumberModel.fromMap(m)).toList();
        _stats = {'total': total, 'called': called, 'remaining': total - called};
      });
      await db.close();
    } catch (e) {
      debugPrint("Database refresh error: $e");
    }
  }

  Future<void> _parseAndAdd() async {
    if (_textController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(p.join(dbPath, 'callcenter.db'));
    for (final number in extractPhoneNumbers(_textController.text)) {
      await db.insert('numbers', {'number': number, 'wasCalled': 0},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    _textController.clear();
    await db.close();
    await _refreshData();
    setState(() => _isLoading = false);
  }

  void _callNext() async {
    if (!await Permission.phone.isGranted) {
      await Permission.phone.request();
      return;
    }
    if (_uiPhoneStatus != PhoneStateStatus.NOTHING && _uiPhoneStatus != PhoneStateStatus.CALL_ENDED) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Already in a call!")),
       );
       return;
    }
    if (_handler != null) {
      await _handler!.play();
    }
    Future.delayed(const Duration(seconds: 1), _refreshData);
  }

  void _toggleAutoDial() async {
    if (_autoDialActive) {
      setState(() => _autoDialActive = false);
      return;
    }
    if (!await Permission.phone.isGranted) {
      await Permission.phone.request();
      return;
    }
    if (_stats['remaining'] == 0 && _stats['total']! > 0) {
      // Reset all numbers and start again
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(p.join(dbPath, 'callcenter.db'));
      await db.update('numbers', {'wasCalled': 0});
      await db.close();
      await _refreshData();
    }
    setState(() => _autoDialActive = true);
    await _autoDialNext();
  }

  Future<void> _autoDialNext() async {
    if (!_autoDialActive) return;
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(p.join(dbPath, 'callcenter.db'));
    final List<Map<String, dynamic>> maps = await db.query(
      'numbers', where: 'wasCalled = ?', whereArgs: [0], limit: 1,
    );
    if (maps.isEmpty) {
      setState(() => _autoDialActive = false);
      await db.close();
      await _refreshData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All calls completed!")),
      );
      return;
    }
    final id = maps.first['id'] as int;
    final number = maps.first['number'] as String;
    await db.update('numbers', {'wasCalled': 1}, where: 'id = ?', whereArgs: [id]);
    await db.close();
    await FlutterPhoneDirectCaller.callNumber(number);
    await _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calling (Headset Enabled)'), centerTitle: true),
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat("TOTAL", _stats['total']!),
                _buildStat("CALLED", _stats['called']!, color: Colors.green),
                _buildStat("PENDING", _stats['remaining']!, color: Colors.orange),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _textController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Paste numbers here",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _parseAndAdd),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 180, height: 180,
                    child: ElevatedButton(
                      onPressed: _toggleAutoDial,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: _autoDialActive ? Colors.red : (_stats['remaining'] == 0 && _stats['total']! > 0 ? Colors.orange : Colors.green),
                        foregroundColor: Colors.white
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _autoDialActive ? Icons.stop :
                            (_stats['remaining'] == 0 && _stats['total']! > 0 ? Icons.refresh : Icons.call),
                            size: 50,
                          ),
                          Text(
                            _autoDialActive ? "STOP" :
                            (_stats['remaining'] == 0 && _stats['total']! > 0 ? "RESET" : "AUTO-DIAL"),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Status: ${_uiPhoneStatus.name}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  if (!_autoDialActive) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _stats['remaining'] == 0 ? null : _callNext,
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text("CALL NEXT"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _numbers.length,
              itemBuilder: (context, i) => ListTile(
                dense: true,
                leading: Icon(_numbers[i].wasCalled ? Icons.check_circle : Icons.circle_outlined, size: 16, color: _numbers[i].wasCalled ? Colors.green : Colors.grey),
                title: Text(_numbers[i].number),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, int val, {Color? color}) {
    return Column(
      children: [
        Text("$val", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart'
    as flutter_midi_command;
import 'package:flutter_midi_command/flutter_midi_command.dart'
    show MidiCommand, MidiPacket;
import '../models/midi_device.dart' as models;
import '../models/midi_message.dart';
import '../models/midi_note_event.dart';

class MidiService {
  static final MidiService _instance = MidiService._internal();
  factory MidiService() => _instance;
  MidiService._internal();

  final MidiCommand _midiCommand = MidiCommand();

  StreamController<List<models.MidiDevice>>? _devicesStreamController;
  StreamController<MidiNoteEvent>? _noteEventsStreamController;
  StreamController<MidiMessage>? _allMessagesStreamController;

  StreamSubscription<MidiPacket>? _midiSubscription;
  StreamSubscription<List<flutter_midi_command.MidiDevice>>?
  _devicesSubscription;

  List<models.MidiDevice> _connectedDevices = [];
  List<models.MidiDevice> _availableInputDevices = [];
  List<models.MidiDevice> _availableOutputDevices = [];

  bool _isInitialized = false;
  bool _isScanning = false;

  // Current active notes (for polyphonic detection compatibility)
  final Map<int, MidiNoteEvent> _activeNotes = {};

  // Getters
  Stream<List<models.MidiDevice>>? get devicesStream =>
      _devicesStreamController?.stream;
  Stream<MidiNoteEvent>? get noteEventsStream =>
      _noteEventsStreamController?.stream;
  Stream<MidiMessage>? get allMessagesStream =>
      _allMessagesStreamController?.stream;

  List<models.MidiDevice> get connectedDevices =>
      List.unmodifiable(_connectedDevices);
  List<models.MidiDevice> get availableInputDevices =>
      List.unmodifiable(_availableInputDevices);
  List<models.MidiDevice> get availableOutputDevices =>
      List.unmodifiable(_availableOutputDevices);
  List<MidiNoteEvent> get activeNotes => _activeNotes.values.toList();

  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  bool get hasConnectedDevices => _connectedDevices.isNotEmpty;

  /// Initialize the MIDI service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('Initializing MIDI service...');

      // Initialize stream controllers
      _devicesStreamController =
          StreamController<List<models.MidiDevice>>.broadcast();
      _noteEventsStreamController = StreamController<MidiNoteEvent>.broadcast();
      _allMessagesStreamController = StreamController<MidiMessage>.broadcast();

      // Start listening for MIDI messages
      _midiSubscription = _midiCommand.onMidiDataReceived?.listen(
        _handleMidiData,
      );

      // Start listening for device changes
      // Note: Device setup change listening may not be available in this version

      // Scan for initial devices
      await scanForDevices();

      _isInitialized = true;
      debugPrint('MIDI service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing MIDI service: $e');
      return false;
    }
  }

  /// Scan for available MIDI devices
  Future<void> scanForDevices() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      debugPrint('Scanning for MIDI devices...');

      // Get available devices
      final devices = await _midiCommand.devices;
      if (devices != null) {
        await _updateDeviceLists(devices);
      }

      _isScanning = false;
      debugPrint(
        'MIDI device scan completed. Found ${_availableInputDevices.length} input devices, ${_availableOutputDevices.length} output devices',
      );
    } catch (e) {
      _isScanning = false;
      debugPrint('Error scanning for MIDI devices: $e');
    }
  }

  /// Connect to a MIDI device
  Future<bool> connectToDevice(models.MidiDevice device) async {
    try {
      debugPrint('Attempting to connect to MIDI device: ${device.name}');

      // Create MidiDevice compatible with flutter_midi_command
      final midiDevice = flutter_midi_command.MidiDevice(
        device.id,
        device.name,
        device.type,
        device.isConnected,
      );
      _midiCommand.connectToDevice(midiDevice);

      // Update our device list
      final updatedDevice = device.copyWith(isConnected: true, isEnabled: true);
      _connectedDevices.removeWhere((d) => d.id == device.id);
      _connectedDevices.add(updatedDevice);

      // Update the appropriate available list
      if (device.type == 'input') {
        _availableInputDevices.removeWhere((d) => d.id == device.id);
        _availableInputDevices.add(updatedDevice);
      } else {
        _availableOutputDevices.removeWhere((d) => d.id == device.id);
        _availableOutputDevices.add(updatedDevice);
      }

      _broadcastDevicesUpdate();
      debugPrint('Successfully connected to MIDI device: ${device.name}');
      return true;
    } catch (e) {
      debugPrint('Error connecting to MIDI device ${device.name}: $e');
      return false;
    }
  }

  /// Disconnect from a MIDI device
  Future<bool> disconnectFromDevice(models.MidiDevice device) async {
    try {
      debugPrint('Attempting to disconnect from MIDI device: ${device.name}');

      // Create MidiDevice compatible with flutter_midi_command
      final midiDevice = flutter_midi_command.MidiDevice(
        device.id,
        device.name,
        device.type,
        device.isConnected,
      );
      _midiCommand.disconnectDevice(midiDevice);

      // Update our device lists
      _connectedDevices.removeWhere((d) => d.id == device.id);

      final disconnectedDevice = device.copyWith(
        isConnected: false,
        isEnabled: false,
      );
      if (device.type == 'input') {
        _availableInputDevices.removeWhere((d) => d.id == device.id);
        _availableInputDevices.add(disconnectedDevice);
      } else {
        _availableOutputDevices.removeWhere((d) => d.id == device.id);
        _availableOutputDevices.add(disconnectedDevice);
      }

      _broadcastDevicesUpdate();
      debugPrint('Successfully disconnected from MIDI device: ${device.name}');
      return true;
    } catch (e) {
      debugPrint('Error disconnecting from MIDI device ${device.name}: $e');
      return false;
    }
  }

  /// Send a MIDI message to connected output devices
  Future<void> sendMidiMessage(Uint8List data) async {
    try {
      final connectedOutputs = _connectedDevices.where(
        (d) => d.type == 'output',
      );
      for (final device in connectedOutputs) {
        _midiCommand.sendData(data);
      }
    } catch (e) {
      debugPrint('Error sending MIDI message: $e');
    }
  }

  /// Send a note on message
  Future<void> sendNoteOn(int channel, int noteNumber, int velocity) async {
    final data = Uint8List.fromList([0x90 | channel, noteNumber, velocity]);
    await sendMidiMessage(data);
  }

  /// Send a note off message
  Future<void> sendNoteOff(int channel, int noteNumber, int velocity) async {
    final data = Uint8List.fromList([0x80 | channel, noteNumber, velocity]);
    await sendMidiMessage(data);
  }

  /// Handle incoming MIDI data
  void _handleMidiData(MidiPacket packet) {
    try {
      final message = MidiMessage.fromData(packet.data, packet.timestamp);

      // Broadcast all messages
      _allMessagesStreamController?.add(message);

      // Process note events specifically
      if (message.type == MidiMessageType.noteOn ||
          message.type == MidiMessageType.noteOff) {
        final noteEvent = MidiNoteEvent.fromMidiNote(
          midiNoteNumber: message.noteNumber!,
          velocity: message.velocity!,
          isNoteOn: message.type == MidiMessageType.noteOn,
          channel: message.channel,
          timestamp: message.timestamp,
        );

        // Update active notes tracking
        if (noteEvent.isNoteOn) {
          _activeNotes[noteEvent.midiNoteNumber] = noteEvent;
        } else {
          _activeNotes.remove(noteEvent.midiNoteNumber);
        }

        // Broadcast note event
        _noteEventsStreamController?.add(noteEvent);

        debugPrint('MIDI Note Event: $noteEvent');
      }
    } catch (e) {
      debugPrint('Error handling MIDI data: $e');
    }
  }

  /// Handle device setup changes
  void _handleDeviceSetupChanged(
    List<flutter_midi_command.MidiDevice> devices,
  ) async {
    debugPrint('MIDI device setup changed');
    await _updateDeviceLists(devices);
  }

  /// Update internal device lists
  Future<void> _updateDeviceLists(
    List<flutter_midi_command.MidiDevice> devices,
  ) async {
    final inputDevices = <models.MidiDevice>[];
    final outputDevices = <models.MidiDevice>[];

    for (final device in devices) {
      final ourDevice = models.MidiDevice(
        id: device.id,
        name: device.name,
        type: device.type,
        isConnected: device.connected,
        isEnabled: device.connected,
      );

      if (device.type == 'input') {
        inputDevices.add(ourDevice);
        if (device.connected) {
          _connectedDevices.removeWhere((d) => d.id == device.id);
          _connectedDevices.add(ourDevice);
        }
      } else if (device.type == 'output') {
        outputDevices.add(ourDevice);
        if (device.connected) {
          _connectedDevices.removeWhere((d) => d.id == device.id);
          _connectedDevices.add(ourDevice);
        }
      }
    }

    _availableInputDevices = inputDevices;
    _availableOutputDevices = outputDevices;

    _broadcastDevicesUpdate();
  }

  /// Broadcast devices update to listeners
  void _broadcastDevicesUpdate() {
    final allDevices = [..._availableInputDevices, ..._availableOutputDevices];
    _devicesStreamController?.add(allDevices);
  }

  /// Clear all active notes (useful for panic/reset)
  void clearActiveNotes() {
    _activeNotes.clear();
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    debugPrint('Disposing MIDI service...');

    _midiSubscription?.cancel();
    _devicesSubscription?.cancel();

    _devicesStreamController?.close();
    _noteEventsStreamController?.close();
    _allMessagesStreamController?.close();

    _connectedDevices.clear();
    _availableInputDevices.clear();
    _availableOutputDevices.clear();
    _activeNotes.clear();

    _isInitialized = false;
    _isScanning = false;

    debugPrint('MIDI service disposed');
  }
}

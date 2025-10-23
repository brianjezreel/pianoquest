import 'package:flutter/material.dart';
import '../../models/midi_device.dart';
import '../../services/midi_service.dart';

class MidiSettingsScreen extends StatefulWidget {
  const MidiSettingsScreen({super.key});

  @override
  State<MidiSettingsScreen> createState() => _MidiSettingsScreenState();
}

class _MidiSettingsScreenState extends State<MidiSettingsScreen> {
  final MidiService _midiService = MidiService();
  List<MidiDevice> _inputDevices = [];
  List<MidiDevice> _outputDevices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeMidi();
  }

  Future<void> _initializeMidi() async {
    await _midiService.initialize();
    await _refreshDevices();
    
    // Listen for device changes
    _midiService.devicesStream?.listen((devices) {
      if (mounted) {
        _updateDeviceLists(devices);
      }
    });
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _isScanning = true;
    });

    await _midiService.scanForDevices();
    _updateDeviceLists([..._midiService.availableInputDevices, ..._midiService.availableOutputDevices]);

    setState(() {
      _isScanning = false;
    });
  }

  void _updateDeviceLists(List<MidiDevice> allDevices) {
    setState(() {
      _inputDevices = allDevices.where((d) => d.type == 'input').toList();
      _outputDevices = allDevices.where((d) => d.type == 'output').toList();
    });
  }

  Future<void> _toggleDeviceConnection(MidiDevice device) async {
    if (device.isConnected) {
      await _midiService.disconnectFromDevice(device);
    } else {
      await _midiService.connectToDevice(device);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIDI Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isScanning 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _refreshDevices,
            tooltip: 'Scan for MIDI devices',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _midiService.hasConnectedDevices ? Icons.check_circle : Icons.info,
                          color: _midiService.hasConnectedDevices ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MIDI Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _midiService.hasConnectedDevices
                          ? 'Connected to ${_midiService.connectedDevices.length} device(s)'
                          : 'No MIDI devices connected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_midiService.isInitialized && !_midiService.hasConnectedDevices)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Connect a MIDI keyboard or controller to use MIDI input in the practice mode.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Input Devices Section
            Text(
              'Input Devices',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MIDI keyboards and controllers that can send note data to the app.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_inputDevices.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.piano,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No MIDI input devices found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Connect a MIDI keyboard and tap refresh',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._inputDevices.map((device) => _buildDeviceCard(device)),

            const SizedBox(height: 24),

            // Output Devices Section
            Text(
              'Output Devices',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MIDI synthesizers and sound modules that can receive note data from the app.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_outputDevices.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.speaker,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No MIDI output devices found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Connect a MIDI synthesizer and tap refresh',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._outputDevices.map((device) => _buildDeviceCard(device)),

            const SizedBox(height: 24),

            // Help Section
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'MIDI Help',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Connect your MIDI keyboard via USB or wireless\n'
                      '• Enable input devices to use MIDI for note detection\n'
                      '• Output devices can be used for playback (future feature)\n'
                      '• Switch to MIDI mode in Practice settings for precise detection',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(MidiDevice device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isConnected ? Colors.green : Colors.grey.shade300,
          child: Icon(
            device.type == 'input' ? Icons.piano : Icons.speaker,
            color: device.isConnected ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.type == 'input' ? 'MIDI Input Device' : 'MIDI Output Device',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (device.isConnected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connected',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: Switch(
          value: device.isConnected,
          onChanged: (value) => _toggleDeviceConnection(device),
          activeColor: Colors.green,
        ),
        onTap: () => _toggleDeviceConnection(device),
      ),
    );
  }
}
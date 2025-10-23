class MidiDevice {
  final String id;
  final String name;
  final String type; // 'input' or 'output'
  final bool isConnected;
  final bool isEnabled;

  const MidiDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = false,
    this.isEnabled = false,
  });

  MidiDevice copyWith({
    String? id,
    String? name,
    String? type,
    bool? isConnected,
    bool? isEnabled,
  }) {
    return MidiDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MidiDevice &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.isConnected == isConnected &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        type.hashCode ^
        isConnected.hashCode ^
        isEnabled.hashCode;
  }

  @override
  String toString() {
    return 'MidiDevice(id: $id, name: $name, type: $type, isConnected: $isConnected, isEnabled: $isEnabled)';
  }
}
class FilterModel {
  final String key;
  final String value;
  final String? description;
  final bool enabled;
  final bool equals;
  final String uuid;

  FilterModel({
    required this.key,
    required this.value,
    this.description,
    required this.enabled,
    required this.equals,
    required this.uuid,
  });

  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      enabled: json['enabled'] as bool,
      equals: json['equals'] as bool,
      uuid: json['uuid'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'enabled': enabled,
      'equals': equals,
      'uuid': uuid,
    };
  }

  FilterModel copyWith({
    String? key,
    String? value,
    String? description,
    bool? enabled,
    bool? equals,
    String? uuid,
  }) {
    return FilterModel(
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      equals: equals ?? this.equals,
      uuid: uuid ?? this.uuid,
    );
  }

  @override
  String toString() {
    return 'FilterModel(key: $key, value: $value, enabled: $enabled, equals: $equals)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterModel && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

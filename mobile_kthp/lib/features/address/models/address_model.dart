class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String province;
  final String ward;
  final String specificAddress;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.province,
    required this.ward,
    required this.specificAddress,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'province': province,
      'ward': ward,
      'specificAddress': specificAddress,
      'isDefault': isDefault,
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      province: map['province'] ?? '',
      ward: map['ward'] ?? '',
      specificAddress: map['specificAddress'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  String get fullAddress => '$specificAddress, $ward, $province';

  AddressModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? province,
    String? ward,
    String? specificAddress,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      province: province ?? this.province,
      ward: ward ?? this.ward,
      specificAddress: specificAddress ?? this.specificAddress,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

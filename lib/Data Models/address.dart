class Address {
  String? id;
  String fullName;
  String email;
  String addressType;
  String addressLine1;
  String? addressLine2;
  String city;
  String state;
  String postalCode;
  String country;
  String phoneNumber;

  Address({
    this.id,
    required this.fullName,
    required this.email,
    required this.addressType,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phoneNumber,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'] ?? json['id'] as String?,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      addressType: json['addressType'] ?? 'Shipping',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'confirmEmail': email,
      'addressType': addressType,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'phoneNumber': phoneNumber,
    };
  }

  // Helper method to get formatted address string
  String get formattedAddress {
    final lines = [addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      lines.add(addressLine2!);
    }
    lines.add('$city, $state $postalCode');
    lines.add(country);
    return lines.join('\n');
  }

  // Helper method to get short address for display
  String get shortAddress {
    return '$city, $state';
  }

  // Copy with method for easy updates
  Address copyWith({
    String? id,
    String? fullName,
    String? email,
    String? addressType,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phoneNumber,
  }) {
    return Address(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      addressType: addressType ?? this.addressType,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.addressType == addressType &&
        other.addressLine1 == addressLine1 &&
        other.addressLine2 == addressLine2 &&
        other.city == city &&
        other.state == state &&
        other.postalCode == postalCode &&
        other.country == country &&
        other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fullName,
      email,
      addressType,
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
      country,
      phoneNumber,
    );
  }

  @override
  String toString() {
    return 'Address(id: $id, fullName: $fullName, city: $city, state: $state)';
  }
}
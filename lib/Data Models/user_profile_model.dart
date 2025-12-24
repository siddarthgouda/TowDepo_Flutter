class UserProfile {
  final String? id;
  final PersonalInformation personalInformation;
  final ChangePassword? changePassword;
  final Information? information;
  final ManageAddress? manageAddress;
  final DateTime? createdOn;
  final DateTime? updatedOn;

  UserProfile({
    this.id,
    required this.personalInformation,
    this.changePassword,
    this.information,
    this.manageAddress,
    this.createdOn,
    this.updatedOn,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'],
      personalInformation: PersonalInformation.fromJson(json['Personal_Information'] ?? {}),
      changePassword: json['Changepassword'] != null
          ? ChangePassword.fromJson(json['Changepassword'])
          : null,
      information: json['Information'] != null
          ? Information.fromJson(json['Information'])
          : null,
      manageAddress: json['ManageAddress'] != null
          ? ManageAddress.fromJson(json['ManageAddress'])
          : null,
      createdOn: json['created_on'] != null ? DateTime.parse(json['created_on']) : null,
      updatedOn: json['updated_on'] != null ? DateTime.parse(json['updated_on']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'Personal_Information': personalInformation.toJson(),
      if (changePassword != null) 'Changepassword': changePassword!.toJson(),
      if (information != null) 'Information': information!.toJson(),
      if (manageAddress != null) 'ManageAddress': manageAddress!.toJson(),
      'created_on': createdOn?.toIso8601String(),
      'updated_on': updatedOn?.toIso8601String(),
    };
  }
}

class PersonalInformation {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? bio;
  final DateTime? dob;

  PersonalInformation({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.bio,
    this.dob,
  });

  factory PersonalInformation.fromJson(Map<String, dynamic> json) {
    return PersonalInformation(
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['Email'],
      phoneNumber: json['phoneNumber'],
      bio: json['bio'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'Email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (bio != null) 'bio': bio,
      if (dob != null) 'dob': dob?.toIso8601String(),
    };
  }

  String get fullName {
    return [firstName, lastName].where((name) => name != null && name.isNotEmpty).join(' ');
  }
}

class ChangePassword {
  final String? password;
  final String? confirmPassword;
  final String? retypePassword;

  ChangePassword({
    this.password,
    this.confirmPassword,
    this.retypePassword,
  });

  factory ChangePassword.fromJson(Map<String, dynamic> json) {
    return ChangePassword(
      password: json['password'],
      confirmPassword: json['confirmPassword'],
      retypePassword: json['RetypePassword'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (password != null) 'password': password,
      if (confirmPassword != null) 'confirmPassword': confirmPassword,
      if (retypePassword != null) 'RetypePassword': retypePassword,
    };
  }
}

class Information {
  final Country? country;
  final String? website;
  final String? phone;

  Information({
    this.country,
    this.website,
    this.phone,
  });

  factory Information.fromJson(Map<String, dynamic> json) {
    return Information(
      country: json['country'] != null ? Country.fromJson(json['country']) : null,
      website: json['website'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (country != null) 'country': country!.toJson(),
      if (website != null) 'website': website,
      if (phone != null) 'phone': phone,
    };
  }
}

class Country {
  final String name;
  final String code;

  Country({
    required this.name,
    required this.code,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }
}

class ManageAddress {
  final String? doorNumber;
  final String? streetName;
  final String? state;
  final String? pinCode;
  final String? permanentDoorNumber;
  final String? permanentStreetName;
  final String? permanentState;
  final String? permanentPinCode;

  ManageAddress({
    this.doorNumber,
    this.streetName,
    this.state,
    this.pinCode,
    this.permanentDoorNumber,
    this.permanentStreetName,
    this.permanentState,
    this.permanentPinCode,
  });

  factory ManageAddress.fromJson(Map<String, dynamic> json) {
    return ManageAddress(
      doorNumber: json['doorNumber'],
      streetName: json['streetName'],
      state: json['state'],
      pinCode: json['pinCode'],
      permanentDoorNumber: json['permanentDoorNumber'],
      permanentStreetName: json['permanentStreetName'],
      permanentState: json['permanentState'],
      permanentPinCode: json['permanentPinCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (doorNumber != null) 'doorNumber': doorNumber,
      if (streetName != null) 'streetName': streetName,
      if (state != null) 'state': state,
      if (pinCode != null) 'pinCode': pinCode,
      if (permanentDoorNumber != null) 'permanentDoorNumber': permanentDoorNumber,
      if (permanentStreetName != null) 'permanentStreetName': permanentStreetName,
      if (permanentState != null) 'permanentState': permanentState,
      if (permanentPinCode != null) 'permanentPinCode': permanentPinCode,
    };
  }

  int get addressCount {
    int count = 0;
    if (doorNumber != null && doorNumber!.isNotEmpty) count++;
    if (permanentDoorNumber != null && permanentDoorNumber!.isNotEmpty) count++;
    return count;
  }

  String get currentAddress {
    if (doorNumber == null || doorNumber!.isEmpty) return 'No current address';
    return '$doorNumber, $streetName, $state - $pinCode'
        .replaceAll('null, ', '')
        .replaceAll('null', '')
        .trim();
  }

  String get permanentAddress {
    if (permanentDoorNumber == null || permanentDoorNumber!.isEmpty) return 'No permanent address';
    return '$permanentDoorNumber, $permanentStreetName, $permanentState - $permanentPinCode'
        .replaceAll('null, ', '')
        .replaceAll('null', '')
        .trim();
  }
}
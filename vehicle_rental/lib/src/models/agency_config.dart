class AgencyConfig {
  final String companyName;
  final String companySlogan;
  final String phone;
  final String email;
  final String address;
  final String? logoUrl;
  final String? paymentQrUrl;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String? khqrData;

  AgencyConfig({
    this.companyName = 'DriveLine',
    this.companySlogan = 'CAR RENTAL',
    this.phone = '+855 23 999 888',
    this.email = 'booking@driveline-rental.com',
    this.address = 'Phnom Penh & Siem Reap, Cambodia',
    this.logoUrl,
    this.paymentQrUrl,
    this.bankName = 'Bakong',
    this.accountName = 'DRIVELINE CAR RENTAL',
    this.accountNumber = '000 892 112',
    this.khqrData,
  });

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'companySlogan': companySlogan,
        'phone': phone,
        'email': email,
        'address': address,
        'logoUrl': logoUrl,
        'paymentQrUrl': paymentQrUrl,
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'khqrData': khqrData,
      };

  factory AgencyConfig.fromJson(Map<String, dynamic> j) {
    final rawSlogan = j['companySlogan'] as String?;
    final resolvedSlogan = (rawSlogan == null || rawSlogan == 'CAR AGENCY')
        ? 'CAR RENTAL'
        : rawSlogan;

    return AgencyConfig(
      companyName: j['companyName'] as String? ?? 'DriveLine',
      companySlogan: resolvedSlogan,
      phone: j['phone'] as String? ?? '+855 23 999 888',
      email: j['email'] as String? ?? 'booking@driveline-rental.com',
      address: j['address'] as String? ?? 'Phnom Penh & Siem Reap, Cambodia',
      logoUrl: j['logoUrl'] as String?,
      paymentQrUrl: j['paymentQrUrl'] as String?,
      bankName: j['bankName'] as String? ?? 'Bakong',
      accountName: j['accountName'] as String? ?? (j['companyName'] as String? ?? 'DRIVELINE CAR RENTAL'),
      accountNumber: j['accountNumber'] as String? ?? '000 892 112',
      khqrData: j['khqrData'] as String?,
    );
  }

  AgencyConfig copyWith({
    String? companyName,
    String? companySlogan,
    String? phone,
    String? email,
    String? address,
    String? logoUrl,
    String? paymentQrUrl,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? khqrData,
  }) {
    return AgencyConfig(
      companyName: companyName ?? this.companyName,
      companySlogan: companySlogan ?? this.companySlogan,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      logoUrl: logoUrl ?? this.logoUrl,
      paymentQrUrl: paymentQrUrl ?? this.paymentQrUrl,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      khqrData: khqrData ?? this.khqrData,
    );
  }
}


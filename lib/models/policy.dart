class Policy {
  int? id;
  String policyType; // e.g., 'Auto Policy', 'Health Insurance Policy'
  String? autoPolicySubType; // e.g., 'Third Party', 'Full', 'OD', 'Only OD', 'other'
  String? policyCompany; // e.g., 'Navi General Insurance Ltd.', 'Reliance General Insurance Co. Ltd.', 'other'
  String? policyStartDate; // Stored as ISO 8601 string (YYYY-MM-DD)
  String? vehicleNumber;
  String customerName;
  String contactNumber;
  double coverageAmount;
  String premiumDueDate; // Stored as ISO 8601 string (YYYY-MM-DD)

  Policy({
    this.id,
    required this.policyType,
    this.autoPolicySubType,
    this.policyCompany,
    this.policyStartDate,
    this.vehicleNumber,
    required this.customerName,
    required this.contactNumber,
    required this.coverageAmount,
    required this.premiumDueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'policyType': policyType,
      'autoPolicySubType': autoPolicySubType,
      'policyCompany': policyCompany,
      'policyStartDate': policyStartDate,
      'vehicleNumber': vehicleNumber,
      'customerName': customerName,
      'contactNumber': contactNumber,
      'coverageAmount': coverageAmount,
      'premiumDueDate': premiumDueDate,
    };
  }

  factory Policy.fromMap(Map<String, dynamic> map) {
    return Policy(
      id: map['id'],
      policyType: map['policyType'],
      autoPolicySubType: map['autoPolicySubType'],
      policyCompany: map['policyCompany'],
      policyStartDate: map['policyStartDate'],
      vehicleNumber: map['vehicleNumber'],
      customerName: map['customerName'],
      contactNumber: map['contactNumber'],
      coverageAmount: map['coverageAmount'],
      premiumDueDate: map['premiumDueDate'],
    );
  }
}

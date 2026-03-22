class StudentModel {
  final String email;
  final String name;
  final String hostelNo;
  final String hostelType; // 'boys' or 'girls'
  final String profilePicUrl;
  final String vendorCode;
  final String billingStatus;
  final int selectedPlan;

  StudentModel({
    required this.email,
    required this.name,
    this.hostelNo = '',
    this.hostelType = '',
    this.profilePicUrl = '',
    this.vendorCode = '',
    this.billingStatus = 'active',
    this.selectedPlan = 1,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      hostelNo: map['hostel_no'] ?? '',
      hostelType: map['hostel_type'] ?? '',
      profilePicUrl: map['profile_pic_url'] ?? '',
      vendorCode: map['vendor_code'] ?? '',
      billingStatus: map['billing_status'] ?? 'active',
      selectedPlan: map['selected_plan'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'hostel_no': hostelNo,
      'hostel_type': hostelType,
      'profile_pic_url': profilePicUrl,
      'vendor_code': vendorCode,
      'billing_status': billingStatus,
      'selected_plan': selectedPlan,
    };
  }

  StudentModel copyWith({
    String? email,
    String? name,
    String? hostelNo,
    String? hostelType,
    String? profilePicUrl,
    String? vendorCode,
    String? billingStatus,
    int? selectedPlan,
  }) {
    return StudentModel(
      email: email ?? this.email,
      name: name ?? this.name,
      hostelNo: hostelNo ?? this.hostelNo,
      hostelType: hostelType ?? this.hostelType,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      vendorCode: vendorCode ?? this.vendorCode,
      billingStatus: billingStatus ?? this.billingStatus,
      selectedPlan: selectedPlan ?? this.selectedPlan,
    );
  }
}

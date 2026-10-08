class RiderProfileDemoData {
  const RiderProfileDemoData({
    this.name = 'Ravi Kumar',
    this.riderId = 'RDR-1001',
    this.mobileNumber = '+91 98765 43210',
    this.alternateNumber = '+91 91234 56789',
    this.emergencyContact = 'Suresh Kumar',
    this.emergencyNumber = '+91 99887 77665',
    this.accountStatus = 'ACTIVE',
    this.verificationStatus = 'VERIFIED',
    this.rating = 4.8,
    this.totalDeliveries = 1248,
    this.completedDeliveries = 1220,
    this.cancelledDeliveries = 28,
    this.totalEarnings = 124800,
    this.monthlyDeliveries = 186,
    this.maskedAadhaar = 'XXXX XXXX 1234',
    this.vehicleType = 'Bike',
    this.vehicleNumber = 'AP 05 XX 1234',
  });

  final String name;
  final String riderId;
  final String mobileNumber;
  final String alternateNumber;
  final String emergencyContact;
  final String emergencyNumber;
  final String accountStatus;
  final String verificationStatus;
  final double rating;
  final int totalDeliveries;
  final int completedDeliveries;
  final int cancelledDeliveries;
  final int totalEarnings;
  final int monthlyDeliveries;
  final String maskedAadhaar;
  final String vehicleType;
  final String vehicleNumber;

  String get totalDeliveriesDisplay => _formatIndianNumber(totalDeliveries);

  String get completedDeliveriesDisplay =>
      _formatIndianNumber(completedDeliveries);

  String get totalEarningsDisplay => '₹${_formatIndianNumber(totalEarnings)}';

  RiderProfileDemoData copyWith({
    String? name,
    String? alternateNumber,
    String? emergencyContact,
    String? emergencyNumber,
  }) => RiderProfileDemoData(
    name: name ?? this.name,
    riderId: riderId,
    mobileNumber: mobileNumber,
    alternateNumber: alternateNumber ?? this.alternateNumber,
    emergencyContact: emergencyContact ?? this.emergencyContact,
    emergencyNumber: emergencyNumber ?? this.emergencyNumber,
    accountStatus: accountStatus,
    verificationStatus: verificationStatus,
    rating: rating,
    totalDeliveries: totalDeliveries,
    completedDeliveries: completedDeliveries,
    cancelledDeliveries: cancelledDeliveries,
    totalEarnings: totalEarnings,
    monthlyDeliveries: monthlyDeliveries,
    maskedAadhaar: maskedAadhaar,
    vehicleType: vehicleType,
    vehicleNumber: vehicleNumber,
  );

  String _formatIndianNumber(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;

    final lastThree = digits.substring(digits.length - 3);
    var prefix = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (prefix.length > 2) {
      groups.insert(0, prefix.substring(prefix.length - 2));
      prefix = prefix.substring(0, prefix.length - 2);
    }
    groups.insert(0, prefix);
    return '${groups.join(',')},$lastThree';
  }
}

/// KLE HOMECARE — ServiceRequest Data Model
/// All ObjectIds from API are plain strings.
class ServiceRequestModel {
  final String  id;
  final String  patientId;
  final String  patientName;
  final String? contactNumber;
  final String? alternativeContact;
  final String  serviceType;
  final String? description;
  final String  address;
  final String  city;
  final String? state;
  final String? pincode;
  final String  preferredDate;
  final String? startDate;
  final String? endDate;
  final int     numDays;
  final String? preferredTime;
  final String  urgencyLevel;
  final String  status;
  final String? specialNotes;
  final double? pricePerDay;
  final double? totalAmount;
  /// List of assigned resource IDs (supports multiple resources per request).
  final List<String> assignedNurseIds;
  /// List of assigned resource names (parallel to [assignedNurseIds]).
  final List<String> assignedNurseNames;
  final String? location;
  final String  createdAt;
  final String  updatedAt;

  const ServiceRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.contactNumber,
    this.alternativeContact,
    required this.serviceType,
    this.description,
    required this.address,
    required this.city,
    this.state,
    this.pincode,
    required this.preferredDate,
    this.startDate,
    this.endDate,
    required this.numDays,
    this.preferredTime,
    required this.urgencyLevel,
    required this.status,
    this.specialNotes,
    this.pricePerDay,
    this.totalAmount,
    this.assignedNurseIds   = const [],
    this.assignedNurseNames = const [],
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  // Backward-compat single-value accessors.
  String? get assignedNurseId   => assignedNurseIds.isNotEmpty   ? assignedNurseIds.first   : null;
  String? get assignedNurseName => assignedNurseNames.isNotEmpty ? assignedNurseNames.first : null;

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id:                  json['id'] as String,
      patientId:           json['patient_id'] as String,
      patientName:         json['patient_name'] as String,
      contactNumber:       json['contact_number'] as String?,
      alternativeContact:  json['alternative_contact'] as String?,
      serviceType:         json['service_type'] as String,
      description:         json['description'] as String?,
      address:             json['address'] as String,
      city:                json['city'] as String,
      state:               json['state'] as String?,
      pincode:             json['pincode'] as String?,
      preferredDate:       json['preferred_date'] as String,
      startDate:           json['start_date'] as String?,
      endDate:             json['end_date'] as String?,
      numDays:             json['num_days'] as int,
      preferredTime:       json['preferred_time'] as String?,
      urgencyLevel:        json['urgency_level'] as String,
      status:              json['status'] as String,
      specialNotes:        json['special_notes'] as String?,
      pricePerDay:         (json['price_per_day'] as num?)?.toDouble(),
      totalAmount:         (json['total_amount'] as num?)?.toDouble(),
      assignedNurseIds:    _parseIds(json),
      assignedNurseNames:  _parseNames(json),
      location:            json['location'] as String?,
      createdAt:           json['created_at'] as String,
      updatedAt:           json['updated_at'] as String,
    );
  }

  /// Parses assigned IDs — supports new array field and legacy single-value field.
  static List<String> _parseIds(Map<String, dynamic> json) {
    final list = json['assigned_nurse_ids'];
    if (list is List) return list.whereType<String>().toList();
    final single = json['assigned_nurse_id'] as String?;
    return single != null ? [single] : [];
  }

  /// Parses assigned names — supports new array field and legacy single-value field.
  static List<String> _parseNames(Map<String, dynamic> json) {
    final list = json['assigned_nurse_names'];
    if (list is List) return list.whereType<String>().toList();
    final single = json['assigned_nurse_name'] as String?;
    return single != null ? [single] : [];
  }

  Map<String, dynamic> toJson() => {
    'id':                    id,
    'patient_id':            patientId,
    'patient_name':          patientName,
    'contact_number':        contactNumber,
    'alternative_contact':   alternativeContact,
    'service_type':          serviceType,
    'description':           description,
    'address':               address,
    'city':                  city,
    'state':                 state,
    'pincode':               pincode,
    'preferred_date':        preferredDate,
    'start_date':            startDate,
    'end_date':              endDate,
    'num_days':              numDays,
    'preferred_time':        preferredTime,
    'urgency_level':         urgencyLevel,
    'status':                status,
    'special_notes':         specialNotes,
    'price_per_day':         pricePerDay,
    'total_amount':          totalAmount,
    'assigned_nurse_ids':    assignedNurseIds,
    'assigned_nurse_names':  assignedNurseNames,
    'location':              location,
    'created_at':            createdAt,
    'updated_at':            updatedAt,
  };
}

// class EventRegistration {
//   final String id;
//   final String eventId;
//   final String userId;
//   final String userName;
//   final String userEmail;
//   final String userPhone;
//   final String studentId;
//   final String department;
//   final String registrationDate;
//   final String status; // 'pending', 'confirmed', 'cancelled'
//   final String? paymentProof;
//   final String? notes;

//   EventRegistration({
//     required this.id,
//     required this.eventId,
//     required this.userId,
//     required this.userName,
//     required this.userEmail,
//     required this.userPhone,
//     required this.studentId,
//     required this.department,
//     required this.registrationDate,
//     required this.status,
//     this.paymentProof,
//     this.notes,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'eventId': eventId,
//       'userId': userId,
//       'userName': userName,
//       'userEmail': userEmail,
//       'userPhone': userPhone,
//       'studentId': studentId,
//       'department': department,
//       'registrationDate': registrationDate,
//       'status': status,
//       'paymentProof': paymentProof,
//       'notes': notes,
//     };
//   }

//   static EventRegistration fromMap(Map<String, dynamic> map) {
//     return EventRegistration(
//       id: map['id'],
//       eventId: map['eventId'],
//       userId: map['userId'],
//       userName: map['userName'],
//       userEmail: map['userEmail'],
//       userPhone: map['userPhone'],
//       studentId: map['studentId'],
//       department: map['department'],
//       registrationDate: map['registrationDate'],
//       status: map['status'],
//       paymentProof: map['paymentProof'],
//       notes: map['notes'],
//     );
//   }
// }
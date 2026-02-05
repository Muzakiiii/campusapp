// import 'package:flutter/material.dart';
// import 'package:campusapp/core/themes/app_theme.dart';
// import 'package:campusapp/features/events/domain/models/event_model.dart';
// import 'package:campusapp/features/events/data/repositories/event_repository.dart';
// import 'package:campusapp/shared/widgets/custom_button.dart';

// class EventDetailScreen extends StatefulWidget {
//   final String eventId;

//   const EventDetailScreen({
//     super.key,
//     required this.eventId,
//   });

//   @override
//   State<EventDetailScreen> createState() => _EventDetailScreenState();
// }

// class _EventDetailScreenState extends State<EventDetailScreen> {
//   late EventRepository _eventRepository;
//   late Event _event;
//   bool _isLoading = true;
//   bool _isBookmarked = false;

//   @override
//   void initState() {
//     super.initState();
//     _eventRepository = EventRepository();
//     _loadEventData();
//   }

//   void _loadEventData() async {
//     final event = _eventRepository.getEventById(widget.eventId);
    
//     if (event != null) {
//       setState(() {
//         _event = event;
//         _isBookmarked = event.isBookmarked;
//         _isLoading = false;
//       });
//     }
//   }

//   void _toggleBookmark() {
//     setState(() {
//       _isBookmarked = !_isBookmarked;
//     });
//     _eventRepository.toggleBookmark(_event.id);
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           _isBookmarked 
//             ? 'Acara disimpan ke bookmark' 
//             : 'Acara dihapus dari bookmark',
//         ),
//         backgroundColor: _isBookmarked ? Colors.green : Colors.grey,
//       ),
//     );
//   }

//   void _registerForEvent() {
//     Navigator.pushNamed(
//       context,
//       '/events/register',
//       arguments: _event,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : CustomScrollView(
//               slivers: [
//                 SliverAppBar(
//                   expandedHeight: 250,
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   pinned: true,
//                   flexibleSpace: FlexibleSpaceBar(
//                     background: Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             AppColors.primary.withOpacity(0.8),
//                             AppColors.primary,
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                       ),
//                       child: SafeArea(
//                         bottom: false,
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             const Spacer(),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 8,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Text(
//                                 _event.category,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 20),
//                               child: Text(
//                                 _event.title,
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 22,
//                                   fontWeight: FontWeight.w700,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   actions: [
//                     IconButton(
//                       onPressed: _toggleBookmark,
//                       icon: Icon(
//                         _isBookmarked
//                             ? Icons.bookmark
//                             : Icons.bookmark_border,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SliverList(
//                   delegate: SliverChildListDelegate([
//                     // Event Content
//                     Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Basic Info Cards
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildInfoCard(
//                                   icon: Icons.calendar_today,
//                                   title: 'Tanggal',
//                                   value: _event.date,
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: _buildInfoCard(
//                                   icon: Icons.access_time,
//                                   title: 'Waktu',
//                                   value: _event.time,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildInfoCard(
//                                   icon: Icons.location_on,
//                                   title: 'Lokasi',
//                                   value: _event.location,
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: _buildInfoCard(
//                                   icon: Icons.people,
//                                   title: 'Peserta',
//                                   value: '${_event.participants} orang',
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 20),
                          
//                           // SKKM & Price
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 8,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.amber.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: Colors.amber.withOpacity(0.2),
//                                   ),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Icon(
//                                       Icons.workspace_premium,
//                                       color: Colors.amber.shade700,
//                                       size: 18,
//                                     ),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       '${_event.skkmPoints} SKKM',
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w700,
//                                         color: Colors.amber.shade700,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const Spacer(),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 8,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: _event.price.toLowerCase() == 'gratis'
//                                       ? Colors.green.withOpacity(0.1)
//                                       : Colors.blue.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: _event.price.toLowerCase() == 'gratis'
//                                         ? Colors.green.withOpacity(0.2)
//                                         : Colors.blue.withOpacity(0.2),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   _event.price,
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w700,
//                                     color: _event.price.toLowerCase() == 'gratis'
//                                         ? Colors.green
//                                         : Colors.blue,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
                          
//                           const SizedBox(height: 25),
                          
//                           // Deskripsi
//                           const Text(
//                             'Deskripsi Acara',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.black,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           Text(
//                             _event.description,
//                             style: TextStyle(
//                               fontSize: 15,
//                               color: Colors.grey.shade700,
//                               height: 1.6,
//                             ),
//                           ),
                          
//                           const SizedBox(height: 25),
                          
//                           // Organizer
//                           Container(
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade50,
//                               borderRadius: BorderRadius.circular(16),
//                               border: Border.all(color: Colors.grey.shade200),
//                             ),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: 50,
//                                   height: 50,
//                                   decoration: BoxDecoration(
//                                     color: AppColors.primary.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Icon(
//                                     Icons.groups,
//                                     color: AppColors.primary,
//                                     size: 24,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'Diselenggarakan oleh',
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         _event.organizer,
//                                         style: const TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w600,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
                          
//                           const SizedBox(height: 30),
                          
//                           // Register Button
//                           _buildRegisterButton(),
                          
//                           const SizedBox(height: 20),
//                         ],
//                       ),
//                     ),
//                   ]),
//                 ),
//               ],
//             ),
//     );
//   }

//   Widget _buildInfoCard({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: AppColors.primary,
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRegisterButton() {
//     if (_event.isRegistered) {
//       return Column(
//         children: [
//           CustomButton(
//             text: 'Sudah Terdaftar',
//             onPressed: () {
//               // Bisa navigasi ke halaman detail pendaftaran
//             },
//             isFullWidth: true,
//             backgroundColor: Colors.grey.shade300,
//             foregroundColor: Colors.grey.shade700,
//           ),
//           const SizedBox(height: 10),
//           TextButton(
//             onPressed: () {
//               // Batal pendaftaran
//             },
//             child: const Text(
//               'Batalkan Pendaftaran',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       );
//     } else {
//       return CustomButton(
//         text: 'Daftar Sekarang',
//         onPressed: _registerForEvent,
//         isFullWidth: true,
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         icon: Icons.arrow_forward,
//       );
//     }
//   }
// }
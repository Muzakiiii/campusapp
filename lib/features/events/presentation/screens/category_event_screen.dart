import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/events/data/repositories/event_repository.dart';

class kategoriEventsScreen extends StatefulWidget {
  final String kategori; // FIX: pakai String
  final EventRepository eventRepository;

  const kategoriEventsScreen({
    super.key,
    required this.kategori,
    required this.eventRepository,
  });

  @override
  State<kategoriEventsScreen> createState() => _kategoriEventsScreenState();
}

class _kategoriEventsScreenState extends State<kategoriEventsScreen> {
  List<EventModel> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // =========================
  // LOAD EVENTS BY CATEGORY
  // =========================
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await widget.eventRepository
          .getEventsBykategori(widget.kategori); // FIX: TANPA .name

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.kategori),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState()
              : _buildEventsList(),
    );
  }

  // =========================
  // EVENTS LIST
  // =========================
  Widget _buildEventsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEventDetail(event),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CATEGORY
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.kategori,
                      style: TextStyle(
                        color: event.categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // TITLE
                  Text(
                    event.judul,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // DATE & TIME
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 4),
                      Text(event.dateText),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text('${event.jamMulai} - ${event.jamSelesai}'),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // LOCATION
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.lokasi)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // PRICE & BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.isGratis
                            ? 'Gratis'
                            : 'Rp ${event.hargaOnline.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showEventDetail(event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Daftar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // EMPTY STATE
  // =========================
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Belum ada event untuk kategori ${widget.kategori}',
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  // =========================
  // EVENT DETAIL
  // =========================
  void _showEventDetail(EventModel event) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              Text(
                event.judul,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(event.deskripsi),
              const SizedBox(height: 12),
              Text('Lokasi: ${event.lokasi}'),
              Text('Tanggal: ${event.dateText}'),
              Text('Waktu: ${event.jamMulai} - ${event.jamSelesai}'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

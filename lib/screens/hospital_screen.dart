import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  bool _isLoading = false;
  Position? _currentPosition;

  final List<Map<String, dynamic>> _nearbyHospitals = [
    {'name': 'Government General Hospital', 'distance': '2.3 km', 'type': 'Government', 'phone': '108'},
    {'name': 'Primary Health Centre', 'distance': '1.1 km', 'type': 'PHC', 'phone': '104'},
    {'name': 'Community Health Centre', 'distance': '3.5 km', 'type': 'CHC', 'phone': '108'},
    {'name': 'District Hospital', 'distance': '5.2 km', 'type': 'Government', 'phone': '108'},
    {'name': 'AIIMS Rural Centre', 'distance': '8.0 km', 'type': 'Government', 'phone': '108'},
  ];

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openMaps(String hospitalName) async {
    final query = Uri.encodeComponent('hospitals near me');
    final url = Uri.parse('https://www.google.com/maps/search/$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _callEmergency() async {
    final url = Uri.parse('tel:108');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A2E), Color(0xFF1A1A4E), Color(0xFF0D2137)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildEmergencyButton(),
              _buildLocationStatus(),
              Expanded(child: _buildHospitalList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Icon(Icons.local_hospital, color: Color(0xFF00D4FF), size: 30),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nearby Hospitals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Find help near you',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return GestureDetector(
      onTap: _callEmergency,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.red, Color(0xFFFF6B6B)]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text(
              'CALL 108 - EMERGENCY AMBULANCE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatus() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            _currentPosition != null ? Icons.location_on : Icons.location_searching,
            color: _currentPosition != null ? const Color(0xFF00FF88) : Colors.white60,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            _currentPosition != null
                ? 'Location found — showing nearby hospitals'
                : _isLoading
                    ? 'Finding your location...'
                    : 'Location not available',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4FF)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHospitalList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: _nearbyHospitals.length,
      itemBuilder: (context, index) {
        final hospital = _nearbyHospitals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D4FF).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
                ),
                child: const Icon(Icons.local_hospital, color: Color(0xFF00D4FF), size: 25),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital['name'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF88).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
                          ),
                          child: Text(
                            hospital['type'],
                            style: const TextStyle(color: Color(0xFF00FF88), fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hospital['distance'],
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openMaps(hospital['name']),
                icon: const Icon(Icons.directions, color: Color(0xFF00D4FF)),
              ),
            ],
          ),
        );
      },
    );
  }
}
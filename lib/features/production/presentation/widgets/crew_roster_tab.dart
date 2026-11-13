import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';

class CrewMember {
  final String id;
  final String name;
  final String role;
  final String department;
  final double dayRate; // KES
  final String phone;
  final bool isBooked;

  const CrewMember({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.dayRate,
    required this.phone,
    this.isBooked = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'department': department,
    'dayRate': dayRate,
    'phone': phone,
    'isBooked': isBooked,
  };

  factory CrewMember.fromJson(Map<String, dynamic> json) => CrewMember(
    id:
        json['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name'] as String? ?? '',
    role: json['role'] as String? ?? '',
    department: json['department'] as String? ?? 'Camera',
    dayRate: (json['dayRate'] as num?)?.toDouble() ?? 25000.0,
    phone: json['phone'] as String? ?? '',
    isBooked: json['isBooked'] as bool? ?? false,
  );
}

class CrewRosterTab extends StatefulWidget {
  const CrewRosterTab({super.key});

  @override
  State<CrewRosterTab> createState() => _CrewRosterTabState();
}

class _CrewRosterTabState extends State<CrewRosterTab> {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'etole_crew_roster_v1';
  String _selectedDepartment = 'All';
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  final List<String> _departments = [
    'All',
    'Camera',
    'Lighting',
    'Sound',
    'Aerial & Drone',
    'Post & Color',
  ];

  static const List<CrewMember> _defaultCrewList = [
    CrewMember(
      id: '1',
      name: 'Dennis K.',
      role: 'Director of Photography (DoP)',
      department: 'Camera',
      dayRate: 45000,
      phone: '+254712345678',
    ),
    CrewMember(
      id: '2',
      name: 'James O.',
      role: '1st Assistant Camera (1st AC / Focus)',
      department: 'Camera',
      dayRate: 25000,
      phone: '+254723456789',
    ),
    CrewMember(
      id: '3',
      name: 'Samson M.',
      role: 'Gaffer / Chief Lighting Tech',
      department: 'Lighting',
      dayRate: 30000,
      phone: '+254734567890',
    ),
    CrewMember(
      id: '4',
      name: 'Victor W.',
      role: 'Production Sound Mixer / Boom Op',
      department: 'Sound',
      dayRate: 28000,
      phone: '+254745678901',
    ),
    CrewMember(
      id: '5',
      name: 'Kelvin T.',
      role: 'KCAA Licensed Drone Pilot',
      department: 'Aerial & Drone',
      dayRate: 35000,
      phone: '+254756789012',
    ),
    CrewMember(
      id: '6',
      name: 'Grace M.',
      role: 'Lead Colorist (DaVinci Resolve)',
      department: 'Post & Color',
      dayRate: 40000,
      phone: '+254767890123',
    ),
  ];

  List<CrewMember> _crewList = [];

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        if (mounted) {
          setState(() {
            _crewList = list
                .map((e) => CrewMember.fromJson(e as Map<String, dynamic>))
                .toList();
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading roster: $e');
    }
    if (mounted) {
      setState(() {
        _crewList = List.from(_defaultCrewList);
      });
    }
  }

  Future<void> _saveRoster() async {
    try {
      final jsonStr = jsonEncode(_crewList.map((c) => c.toJson()).toList());
      await _storage.write(key: _storageKey, value: jsonStr);
    } catch (e) {
      debugPrint('Error saving roster: $e');
    }
  }

  Future<void> _checkAvailability(CrewMember crew) async {
    EtoleHaptics.selection();
    final clean = crew.phone.replaceAll(RegExp(r'\D'), '');
    final text =
        'Hi ${crew.name}! Checking your availability from our creative production team for an upcoming commercial shoot as ${crew.role} at your day rate of KES ${_currencyFormat.format(crew.dayRate)}/day. Let us know what your dates look like!';
    final uri = Uri.parse(
      'https://wa.me/$clean?text=${Uri.encodeComponent(text)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability check copied to clipboard!'),
          ),
        );
      }
    }
  }

  void _showAddCrewDialog() {
    EtoleHaptics.selection();
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String dept = 'Camera';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: const Color(0xFA121518),
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: EtoleColors.creamMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Add Crew Member to Day-Rate Roster',
                  style: EtoleTypography.h3.copyWith(
                    color: EtoleColors.cream,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Color(0xFF00838F)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: roleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Production Role (e.g. 1st AC, Gaffer)',
                    labelStyle: TextStyle(color: Color(0xFF00838F)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Negotiated Day Rate (KES)',
                    labelStyle: TextStyle(color: Color(0xFF00838F)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone / WhatsApp',
                    labelStyle: TextStyle(color: Color(0xFF00838F)),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00838F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final rate =
                        double.tryParse(
                          rateCtrl.text.replaceAll(RegExp(r'[^\d.]'), ''),
                        ) ??
                        25000;
                    if (nameCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _crewList.add(
                          CrewMember(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: nameCtrl.text.trim(),
                            role: roleCtrl.text.trim().isNotEmpty
                                ? roleCtrl.text.trim()
                                : 'Production Crew',
                            department: dept,
                            dayRate: rate,
                            phone: phoneCtrl.text.trim(),
                          ),
                        );
                      });
                      _saveRoster();
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    'Save to Roster',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCrewDialog(CrewMember crew) {
    EtoleHaptics.selection();
    final nameCtrl = TextEditingController(text: crew.name);
    final roleCtrl = TextEditingController(text: crew.role);
    final rateCtrl = TextEditingController(
      text: crew.dayRate.toInt().toString(),
    );
    final phoneCtrl = TextEditingController(text: crew.phone);
    String dept = crew.department;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: const Color(0xFA121518),
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: EtoleColors.creamMuted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Edit Crew Member Details',
                    style: EtoleTypography.h3.copyWith(
                      color: EtoleColors.cream,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: Color(0xFF00838F)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: roleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Production Role (e.g. 1st AC, Gaffer)',
                      labelStyle: TextStyle(color: Color(0xFF00838F)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _departments.contains(dept) && dept != 'All'
                        ? dept
                        : 'Camera',
                    dropdownColor: const Color(0xFF1E242B),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      labelStyle: TextStyle(color: Color(0xFF00838F)),
                    ),
                    items: _departments.where((d) => d != 'All').map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => dept = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Negotiated Day Rate (KES)',
                      labelStyle: TextStyle(color: Color(0xFF00838F)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Phone / WhatsApp',
                      labelStyle: TextStyle(color: Color(0xFF00838F)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00838F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final rate =
                          double.tryParse(
                            rateCtrl.text.replaceAll(RegExp(r'[^\d.]'), ''),
                          ) ??
                          crew.dayRate;
                      final index = _crewList.indexWhere(
                        (c) => c.id == crew.id,
                      );
                      if (index != -1 && nameCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _crewList[index] = CrewMember(
                            id: crew.id,
                            name: nameCtrl.text.trim(),
                            role: roleCtrl.text.trim().isNotEmpty
                                ? roleCtrl.text.trim()
                                : crew.role,
                            department: dept,
                            dayRate: rate,
                            phone: phoneCtrl.text.trim(),
                            isBooked: crew.isBooked,
                          );
                        });
                        _saveRoster();
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCrew(CrewMember crew) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171B),
        title: const Text(
          'Remove from Roster?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "${crew.name}" (${crew.role}) from your production crew roster?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _crewList.removeWhere((c) => c.id == crew.id);
      });
      await _saveRoster();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${crew.name} removed from roster.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedDepartment == 'All'
        ? _crewList
        : _crewList.where((c) => c.department == _selectedDepartment).toList();

    return Column(
      children: [
        // Department Chips & Add Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _departments.map((dept) {
                      final isSelected = _selectedDepartment == dept;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            EtoleHaptics.light();
                            setState(() => _selectedDepartment = dept);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00838F)
                                        .withValues(alpha: 0.25)
                                  : const Color(0xFF13171B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00838F)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Text(
                              dept,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF00838F)
                      .withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFF26C6DA),
                  size: 18,
                ),
                tooltip: 'Add Crew',
                onPressed: _showAddCrewDialog,
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Crew Roster List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final crew = filtered[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171B),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  border: Border.all(
                    color: const Color(0xFF00838F).withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF1E242B),
                      child: Text(
                        crew.name[0],
                        style: const TextStyle(
                          color: Color(0xFF26C6DA),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                crew.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00838F)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  crew.department.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF26C6DA),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            crew.role,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Day Rate: KES ${_currencyFormat.format(crew.dayRate)}/day',
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF26C6DA),
                            size: 17,
                          ),
                          tooltip: 'Edit Member',
                          onPressed: () => _showEditCrewDialog(crew),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 17,
                          ),
                          tooltip: 'Remove',
                          onPressed: () => _confirmDeleteCrew(crew),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _checkAvailability(crew),
                          icon: const Icon(Icons.send_rounded, size: 12),
                          label: const Text(
                            'Book',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

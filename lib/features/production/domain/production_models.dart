import 'package:flutter/material.dart';

import '../../../../core/design_system/etole_colors.dart';

enum ProductionStage {
  preProduction(
    'pre_production',
    'Pre-Production',
    Icons.movie_edit,
    Color(0xFF6366F1),
  ),
  production(
    'production',
    'Principal Photography',
    Icons.videocam_rounded,
    EtoleColors.cyan,
  ),
  postProduction(
    'post_production',
    'Post-Production',
    Icons.auto_fix_high_rounded,
    Color(0xFFA855F7),
  ),
  clientReview(
    'client_review',
    'Client Review',
    Icons.rate_review_rounded,
    Color(0xFFF59E0B),
  ),
  delivered(
    'delivered',
    'Delivered & Wrapped',
    Icons.verified_rounded,
    Color(0xFF10B981),
  ),
  archived('archived', 'Archived', Icons.archive_outlined, Color(0xFF6B7280));

  final String code;
  final String label;
  final IconData icon;
  final Color color;

  const ProductionStage(this.code, this.label, this.icon, this.color);

  static ProductionStage fromCode(String? code) {
    return ProductionStage.values.firstWhere(
      (s) => s.code == code,
      orElse: () => ProductionStage.preProduction,
    );
  }
}

class CrewMember {
  final String role;
  final String name;
  final String phone;
  final String callTime;

  CrewMember({
    required this.role,
    required this.name,
    required this.phone,
    required this.callTime,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      role: json['role'] as String? ?? 'Crew',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      callTime: json['callTime'] as String? ?? '06:00 AM',
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'name': name,
    'phone': phone,
    'callTime': callTime,
  };
}

class ScheduleScene {
  final String time;
  final String scene;
  final String description;
  final String location;

  ScheduleScene({
    required this.time,
    required this.scene,
    required this.description,
    required this.location,
  });

  factory ScheduleScene.fromJson(Map<String, dynamic> json) {
    return ScheduleScene(
      time: json['time'] as String? ?? '',
      scene: json['scene'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'scene': scene,
    'description': description,
    'location': location,
  };
}

class DeliveryLinkItem {
  final String platform;
  final String url;
  final String label;

  DeliveryLinkItem({
    required this.platform,
    required this.url,
    required this.label,
  });

  factory DeliveryLinkItem.fromJson(Map<String, dynamic> json) {
    return DeliveryLinkItem(
      platform: json['platform'] as String? ?? 'Drive',
      url: json['url'] as String? ?? '',
      label: json['label'] as String? ?? 'Masters',
    );
  }

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'url': url,
    'label': label,
  };
}

class MilestoneItem {
  final String id;
  final String title;
  final bool isDone;
  final String? dueDate;

  MilestoneItem({
    required this.id,
    required this.title,
    required this.isDone,
    this.dueDate,
  });

  factory MilestoneItem.fromJson(Map<String, dynamic> json) {
    return MilestoneItem(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
      dueDate: json['dueDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isDone': isDone,
    'dueDate': dueDate,
  };
}

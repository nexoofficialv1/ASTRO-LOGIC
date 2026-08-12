import 'package:flutter/material.dart';

enum AstroModuleAvailability { available, comingSoon }

class AstroModule {
  const AstroModule({
    required this.copyKey,
    required this.icon,
    required this.color,
    this.availability = AstroModuleAvailability.available,
  });

  final String copyKey;
  final IconData icon;
  final Color color;
  final AstroModuleAvailability availability;
}

const astroModules = <AstroModule>[
  AstroModule(copyKey: 'clients', icon: Icons.people_alt_outlined, color: Color(0xFF56C7B7)),
  AstroModule(copyKey: 'vedic', icon: Icons.brightness_7_outlined, color: Color(0xFFF3B75B)),
  AstroModule(copyKey: 'kp', icon: Icons.hub_outlined, color: Color(0xFF8FA8FF)),
  AstroModule(
    copyKey: 'western',
    icon: Icons.public_outlined,
    color: Color(0xFFD7A4FF),
  ),
  AstroModule(copyKey: 'numerology', icon: Icons.calculate_outlined, color: Color(0xFFFF8F91)),
  AstroModule(
    copyKey: 'vastu',
    icon: Icons.grid_4x4_outlined,
    color: Color(0xFF72C5F5),
    availability: AstroModuleAvailability.comingSoon,
  ),
  AstroModule(
    copyKey: 'palmistry',
    icon: Icons.pan_tool_alt_outlined,
    color: Color(0xFFE8A7C8),
    availability: AstroModuleAvailability.comingSoon,
  ),
  AstroModule(copyKey: 'gemstoneRemedies', icon: Icons.diamond_outlined, color: Color(0xFF6ED6E8)),
  AstroModule(copyKey: 'reports', icon: Icons.description_outlined, color: Color(0xFF85D58A)),
  AstroModule(
    copyKey: 'practice',
    icon: Icons.event_note_outlined,
    color: Color(0xFFF1D26A),
    availability: AstroModuleAvailability.comingSoon,
  ),
  AstroModule(copyKey: 'settings', icon: Icons.tune_outlined, color: Color(0xFFB0BEC5)),
];

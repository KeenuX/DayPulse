import 'package:flutter/material.dart';

enum TimeBlockType {
  morning('Morning', Icons.wb_sunny_outlined, 'Before 12:00 PM'),
  afternoon('Afternoon', Icons.wb_twilight_rounded, '12:00 PM – 5:00 PM'),
  evening('Evening', Icons.nightlight_round, '5:00 PM onwards'),
  unscheduled('Anytime', Icons.access_time_rounded, 'No specific time');

  final String title;
  final IconData icon;
  final String description;

  const TimeBlockType(this.title, this.icon, this.description);
}
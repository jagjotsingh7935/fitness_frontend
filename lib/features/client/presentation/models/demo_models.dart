import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ClientNotification {
  const ClientNotification({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
  });

  final String icon;
  final String title;
  final String body;
  final String time;
  final Color color;
}

class WorkoutCardModel {
  const WorkoutCardModel({
    required this.badge,
    required this.icon,
    required this.name,
    required this.durationLabel,
    required this.caloriesLabel,
    required this.progress,
    this.featured = false,
  });

  final String badge;
  final String icon;
  final String name;
  final String durationLabel;
  final String caloriesLabel;
  final double progress; // 0..1
  final bool featured;
}

class ExerciseModel {
  const ExerciseModel({
    required this.emoji,
    required this.name,
    required this.detail,
    required this.totalSets,
    required this.doneSets,
  });

  final String emoji;
  final String name;
  final String detail;
  final int totalSets;
  final int doneSets;
}

class MealModel {
  const MealModel({
    required this.emoji,
    required this.name,
    required this.timeLabel,
    required this.caloriesLabel,
    required this.done,
  });

  final String emoji;
  final String name;
  final String timeLabel;
  final String caloriesLabel;
  final bool done;

  MealModel copyWith({bool? done}) => MealModel(
        emoji: emoji,
        name: name,
        timeLabel: timeLabel,
        caloriesLabel: caloriesLabel,
        done: done ?? this.done,
      );
}

class VideoModel {
  const VideoModel({
    required this.emoji,
    required this.title,
    required this.meta,
    required this.duration,
    required this.gradient,
  });

  final String emoji;
  final String title;
  final String meta;
  final String duration;
  final List<Color> gradient;
}

class DemoClientData {
  static const notifications = <ClientNotification>[
    ClientNotification(
      icon: '💪',
      title: 'Time to Workout!',
      body: 'Your Upper Body Blast session is scheduled for today.',
      time: '2 min ago',
      color: Color(0xFF2C4BFF),
    ),
    ClientNotification(
      icon: '🥗',
      title: 'Lunch Reminder',
      body: "Don't forget your chicken rice bowl — it's almost 1 PM!",
      time: '28 min ago',
      color: AppColors.green,
    ),
    ClientNotification(
      icon: '🏆',
      title: 'New Badge Earned!',
      body: "You've reached a 10-day streak. Keep it going!",
      time: '2 hours ago',
      color: AppColors.yellow,
    ),
    ClientNotification(
      icon: '📹',
      title: 'New Video Available',
      body: 'Trainer Rahul uploaded: "HIIT Cardio for Beginners"',
      time: 'Yesterday',
      color: AppColors.accent,
    ),
  ];

  static const workoutCards = <WorkoutCardModel>[
    WorkoutCardModel(
      badge: '⭐ Featured',
      icon: '🏋️',
      name: 'Upper Body Blast',
      durationLabel: '45m',
      caloriesLabel: '🔥 380 cal',
      progress: 0.64,
      featured: true,
    ),
    WorkoutCardModel(
      badge: '🏃 Cardio',
      icon: '🚴',
      name: 'HIIT Cycling',
      durationLabel: '30m',
      caloriesLabel: '🔥 280 cal',
      progress: 0,
    ),
    WorkoutCardModel(
      badge: '🧘 Recovery',
      icon: '🧘',
      name: 'Yoga Stretch',
      durationLabel: '20m',
      caloriesLabel: '🔥 90 cal',
      progress: 1,
    ),
  ];

  static const exercises = <ExerciseModel>[
    ExerciseModel(
      emoji: '🏋️‍♂️',
      name: 'Bench Press',
      detail: '4 sets × 12 reps',
      totalSets: 4,
      doneSets: 3,
    ),
    ExerciseModel(
      emoji: '💪',
      name: 'Bicep Curls',
      detail: '3 sets × 15 reps',
      totalSets: 3,
      doneSets: 2,
    ),
    ExerciseModel(
      emoji: '🦵',
      name: 'Squats',
      detail: '4 sets × 10 reps',
      totalSets: 4,
      doneSets: 1,
    ),
    ExerciseModel(
      emoji: '🤸',
      name: 'Pull-Ups',
      detail: '3 sets × 8 reps',
      totalSets: 3,
      doneSets: 0,
    ),
    ExerciseModel(
      emoji: '🧗',
      name: 'Deadlift',
      detail: '3 sets × 8 reps',
      totalSets: 3,
      doneSets: 3,
    ),
    ExerciseModel(
      emoji: '🏃',
      name: 'Treadmill Run',
      detail: '20 min · 6 km/h',
      totalSets: 2,
      doneSets: 2,
    ),
    ExerciseModel(
      emoji: '🔄',
      name: 'Lat Pulldown',
      detail: '4 sets × 12 reps',
      totalSets: 4,
      doneSets: 0,
    ),
    ExerciseModel(
      emoji: '🧘',
      name: 'Plank Hold',
      detail: '3 × 60 seconds',
      totalSets: 3,
      doneSets: 1,
    ),
  ];

  static const meals = <MealModel>[
    MealModel(
      emoji: '🌅',
      name: 'Oats + Banana Smoothie',
      timeLabel: '7:00 AM · Breakfast',
      caloriesLabel: '380 cal',
      done: true,
    ),
    MealModel(
      emoji: '🥚',
      name: 'Boiled Eggs + Toast',
      timeLabel: '10:00 AM · Mid Morning',
      caloriesLabel: '220 cal',
      done: true,
    ),
    MealModel(
      emoji: '🍛',
      name: 'Chicken Rice Bowl',
      timeLabel: '1:00 PM · Lunch',
      caloriesLabel: '540 cal',
      done: false,
    ),
    MealModel(
      emoji: '🥜',
      name: 'Mixed Nuts + Whey',
      timeLabel: '4:00 PM · Snack',
      caloriesLabel: '310 cal',
      done: false,
    ),
    MealModel(
      emoji: '🐟',
      name: 'Grilled Fish + Salad',
      timeLabel: '7:30 PM · Dinner',
      caloriesLabel: '450 cal',
      done: false,
    ),
  ];

  static const videosWorkoutTutorials = <VideoModel>[
    VideoModel(
      emoji: '💪',
      title: 'Bicep & Tricep Superset',
      meta: 'Intermediate · 180 cal',
      duration: '15:20',
      gradient: [Color(0xFF1A237E), Color(0xFF4A148C)],
    ),
    VideoModel(
      emoji: '🏃',
      title: 'HIIT Cardio Blast',
      meta: 'Advanced · 320 cal',
      duration: '22:10',
      gradient: [Color(0xFF004D40), Color(0xFF006064)],
    ),
    VideoModel(
      emoji: '🦵',
      title: 'Leg Day Destroyer',
      meta: 'Advanced · 260 cal',
      duration: '18:45',
      gradient: [Color(0xFFBF360C), Color(0xFFE64A19)],
    ),
  ];

  static const videosDietNutrition = <VideoModel>[
    VideoModel(
      emoji: '🥗',
      title: 'Meal Prep for Weight Loss',
      meta: 'Trainer Rahul',
      duration: '8:30',
      gradient: [Color(0xFF33691E), Color(0xFF558B2F)],
    ),
    VideoModel(
      emoji: '🥩',
      title: 'High Protein Indian Diet',
      meta: 'Trainer Rahul',
      duration: '11:15',
      gradient: [Color(0xFFE65100), Color(0xFFF57C00)],
    ),
    VideoModel(
      emoji: '💊',
      title: 'Supplements Explained',
      meta: 'Nutrition Guide',
      duration: '6:45',
      gradient: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    ),
  ];

  static const videosRecoveryWellness = <VideoModel>[
    VideoModel(
      emoji: '🧘',
      title: 'Full Body Yoga Flow',
      meta: 'Beginner Friendly',
      duration: '20:00',
      gradient: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
    ),
    VideoModel(
      emoji: '😴',
      title: 'Sleep & Recovery Tips',
      meta: 'Wellness · 5 min',
      duration: '5:00',
      gradient: [Color(0xFF006064), Color(0xFF00838F)],
    ),
  ];
}


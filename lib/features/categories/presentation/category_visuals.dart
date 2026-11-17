import 'package:flutter/material.dart';

/// Curated icon set; the key is what gets stored in the database.
const Map<String, IconData> categoryIcons = {
  'home': Icons.home,
  'food': Icons.restaurant,
  'groceries': Icons.shopping_cart,
  'transport': Icons.directions_car,
  'health': Icons.favorite,
  'education': Icons.school,
  'entertainment': Icons.movie,
  'shopping': Icons.shopping_bag,
  'bills': Icons.receipt_long,
  'travel': Icons.flight,
  'savings': Icons.savings,
  'work': Icons.work,
  'gift': Icons.card_giftcard,
  'phone': Icons.phone_android,
  'pets': Icons.pets,
  'other': Icons.category,
};

IconData iconForKey(String? key) => categoryIcons[key] ?? Icons.category;

/// Palette of ARGB ints.
const List<int> categoryColors = [
  0xFFE53935,
  0xFFD81B60,
  0xFF8E24AA,
  0xFF3949AB,
  0xFF1E88E5,
  0xFF00ACC1,
  0xFF00897B,
  0xFF43A047,
  0xFFFB8C00,
  0xFF6D4C41,
  0xFF546E7A,
];

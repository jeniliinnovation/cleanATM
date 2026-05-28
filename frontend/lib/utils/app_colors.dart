import 'package:flutter/material.dart';

class AppColors {
  // ─── Brand ────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF10B981); // Emerald-500 — used throughout the app
  static const Color primaryDark  = Color(0xFF059669); // Emerald-600 — darker shade / gradient end
  static const Color primaryLight = Color(0xFFDCFCE7); // Emerald-100 — light tint backgrounds
  static const Color primaryVariant = Color(0xFF34D399); // Emerald-400 — lighter variant

  // ─── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background      = Color(0xFFF9FFF9); // app scaffold background
  static const Color surfaceLight    = Color(0xFFF8FAFC); // Slate-50
  static const Color surfaceMuted    = Color(0xFFF1F5F9); // Slate-100
  static const Color inputBackground = Color(0xFFFFFFFF);

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1E293B); // Slate-800
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textMuted     = Color(0xFF94A3B8); // Slate-400
  static const Color textDark      = Color(0xFF334155); // Slate-700

  // ─── Borders / Dividers ───────────────────────────────────────────────────
  static const Color border       = Color(0xFFF1F5F9); // Slate-100
  static const Color borderMuted  = Color(0xFFCBD5E1); // Slate-300

  // ─── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // same as primary
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);

  // ─── Accents ──────────────────────────────────────────────────────────────
  static const Color accentBlue   = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // ─── Glassmorphism / Effects ──────────────────────────────────────────────
  // ignore: deprecated_member_use
  static Color glassWhite  = Colors.white.withOpacity(0.7);
  // ignore: deprecated_member_use
  static Color glassBorder = Colors.white.withOpacity(0.3);
}

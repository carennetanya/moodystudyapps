package com.example.moody_study_backend.entity;

/**
 * 10 pool quest harian yang tersedia.
 * Setiap hari sistem memilih 3 secara random untuk setiap user.
 */
public enum QuestKey {

    /** Selesaikan 1 sesi belajar pertama hari ini (durasi bebas). +10 Coin */
    FIRST_SESSION,

    /** Selesaikan 1 sesi belajar (min 25 menit) dengan 0 kali distraksi. +25 Coin */
    ZERO_DISTRACTION,

    /** Selesaikan total minimal 3 sesi belajar dalam satu hari. +25 Coin */
    MARATHON,

    /** Selesaikan 1 sesi belajar dengan durasi minimal 30 menit. +15 Coin */
    LONG_FOCUS,

    /** Selesaikan 1 sesi belajar dengan jumlah distraksi maksimal 2 kali. +15 Coin */
    TOLERANCE_LIMIT,

    /** Selesaikan minimal 1 sesi belajar sebelum jam 10:00. +15 Coin */
    MORNING_WARRIOR,

    /** Selesaikan minimal 1 sesi belajar di atas jam 19:00. +15 Coin */
    NIGHT_FIGHTER,

    /** Selesaikan 2 sesi belajar berturut-turut dengan jeda istirahat maks 10 menit. +20 Coin */
    DOUBLE_SESSION,

    /** Mulai sesi belajar di jam yang sama seperti hari kemarin (toleransi 30 menit). +20 Coin */
    CONSISTENCY_HOUR,

    /** Buka halaman statistik belajar. +5 Coin */
    REVIEW_STATS
}

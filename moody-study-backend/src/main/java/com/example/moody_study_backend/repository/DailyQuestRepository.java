package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.DailyQuest;
import com.example.moody_study_backend.entity.QuestKey;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DailyQuestRepository extends JpaRepository<DailyQuest, Long> {

    /** Ambil semua quest user untuk tanggal tertentu. */
    List<DailyQuest> findByUserAndQuestDate(User user, LocalDate questDate);

    /** Cek apakah quest tertentu sudah ada untuk user dan tanggal tertentu. */
    boolean existsByUserAndQuestDateAndQuestKey(User user, LocalDate questDate, QuestKey questKey);

    /** Ambil quest spesifik user berdasarkan tanggal dan key. */
    Optional<DailyQuest> findByUserAndQuestDateAndQuestKey(User user, LocalDate questDate, QuestKey questKey);
}
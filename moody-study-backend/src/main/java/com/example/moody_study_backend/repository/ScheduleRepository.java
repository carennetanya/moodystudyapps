package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.Schedule;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Repository
public interface ScheduleRepository extends JpaRepository<Schedule, Long> {

    List<Schedule> findByUserOrderByStudyDateAscStartTimeAsc(User user);

    // Dipakai NotificationSchedulerService: cari jadwal hari ini yang mulai dalam window tertentu & belum selesai
    List<Schedule> findByStudyDateAndStartTimeBetweenAndIsCompletedFalse(
            LocalDate studyDate,
            LocalTime startTimeAfter,
            LocalTime startTimeBefore
    );
}
package com.example.moody_study_backend.services;

import com.example.moody_study_backend.entity.Notification;
import com.example.moody_study_backend.entity.Schedule;
import com.example.moody_study_backend.repository.NotificationRepository;
import com.example.moody_study_backend.repository.ScheduleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@EnableScheduling
@Slf4j
public class NotificationSchedulerService {

    private final ScheduleRepository scheduleRepository;
    private final NotificationRepository notificationRepository;

    // Jalan tiap 1 menit
    @Scheduled(fixedRate = 60000)
    public void checkUpcomingSchedules() {
        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();

        // Window: jadwal yang mulai antara 14-16 menit dari sekarang (supaya tidak terlewat/dobel)
        LocalTime windowStart = now.plusMinutes(14);
        LocalTime windowEnd = now.plusMinutes(16);

        List<Schedule> schedules = scheduleRepository
                .findByStudyDateAndStartTimeBetweenAndIsCompletedFalse(today, windowStart, windowEnd);

        for (Schedule schedule : schedules) {
            // Skip jika notif untuk schedule ini sudah pernah dibuat
            if (notificationRepository.existsBySchedule(schedule)) {
                continue;
            }

            Notification notif = Notification.builder()
                    .user(schedule.getUser())
                    .schedule(schedule)
                    .message("Jadwal belajar \"" + schedule.getSubject() + "\" akan dimulai 15 menit lagi!")
                    .isRead(false)
                    .createdAt(LocalDateTime.now())
                    .build();

            notificationRepository.save(notif);
            log.info("Notifikasi dibuat untuk user {} - jadwal: {}", schedule.getUser().getEmail(), schedule.getSubject());
        }
    }
}
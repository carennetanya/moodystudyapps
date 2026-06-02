package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.entity.Notification;
import com.example.moody_study_backend.entity.Schedule;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.NotificationRepository;
import com.example.moody_study_backend.repository.ScheduleRepository;

@ExtendWith(MockitoExtension.class)
class NotificationSchedulerServiceTest {

    @Mock
    ScheduleRepository scheduleRepository;

    @Mock
    NotificationRepository notificationRepository;

    @InjectMocks
    NotificationSchedulerService notificationSchedulerService;

    @Test
    void checkUpcomingSchedules_shouldCreateNotification() {
        User user = new User();
        user.setEmail("test@gmail.com");
        Schedule schedule = Schedule.builder().user(user).subject("Math").studyDate(LocalDate.now()).startTime(LocalTime.now().plusMinutes(15)).isCompleted(false).build();

        when(scheduleRepository.findByStudyDateAndStartTimeBetweenAndIsCompletedFalse(any(LocalDate.class), any(LocalTime.class), any(LocalTime.class)))
                .thenReturn(List.of(schedule));
        when(notificationRepository.existsBySchedule(any(Schedule.class))).thenReturn(false);
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));

        notificationSchedulerService.checkUpcomingSchedules();

        verify(notificationRepository).save(any(Notification.class));
    }
}

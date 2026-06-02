package com.example.moody_study_backend.services;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.dto.ScheduleRequest;
import com.example.moody_study_backend.entity.Schedule;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.ScheduleRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class ScheduleServiceTest {

    @Mock
    ScheduleRepository scheduleRepository;

    @Mock
    UserRepository userRepository;

    @InjectMocks
    ScheduleService scheduleService;

    @Test
    void createSchedule_shouldSaveSchedule() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(scheduleRepository.save(any(Schedule.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ScheduleRequest request = new ScheduleRequest();
        request.setSubject("Math");
        request.setStudyDate("2026-06-10");
        request.setStartTime("09:00");
        request.setEndTime("10:00");

        assertNotNull(scheduleService.createSchedule("test@gmail.com", request));
    }

    @Test
    void deleteSchedule_shouldDeleteById() {
        scheduleService.deleteSchedule(1L);

        verify(scheduleRepository).deleteById(1L);
    }
}

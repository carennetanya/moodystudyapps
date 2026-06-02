package com.example.moody_study_backend.services;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.dto.AutoScheduleRequest;
import com.example.moody_study_backend.dto.ScheduleResponse;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.ScheduleRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

@ExtendWith(MockitoExtension.class)
class AutoScheduleServiceTest {

    @Mock
    ScheduleRepository scheduleRepository;

    @Mock
    StudySessionRepository studySessionRepository;

    @Mock
    UserRepository userRepository;

    ObjectMapper objectMapper = new ObjectMapper();

    private static class TestGeminiService extends GeminiService {
        TestGeminiService() {
            super(new org.springframework.web.client.RestTemplate());
        }

        @Override
        public String generateAutoSchedule(String sessionHistoryJson, String existingSchedules, int daysAhead, String additionalInstructions) {
            return "[{\"subject\": \"Math\", \"studyDate\": \"2026-06-10\", \"startTime\": \"09:00\", \"endTime\": \"10:00\", \"location\": \"Room 1\", \"mood\": \"Focus\", \"reason\": \"review\"}]";
        }
    }

    @Test
    void generateAutoSchedule_shouldReturnSuggestedSchedules() throws Exception {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(studySessionRepository.findByUserOrderByStartTimeDesc(user)).thenReturn(List.of());
        when(scheduleRepository.findByUserOrderByStudyDateAscStartTimeAsc(user)).thenReturn(List.of());
        AutoScheduleRequest request = new AutoScheduleRequest();
        request.setDaysAhead(3);
        request.setSubjects(List.of("Math"));
        request.setAvailableDays(List.of("Monday"));
        request.setStartHour("08:00");
        request.setEndHour("10:00");
        request.setDurationMinutes(60);

        AutoScheduleService autoScheduleService = new AutoScheduleService(
                scheduleRepository,
                studySessionRepository,
                userRepository,
                new TestGeminiService(),
                objectMapper
        );

        List<ScheduleResponse> result = autoScheduleService.generateAutoSchedule("test@gmail.com", request);

        assertEquals(1, result.size());
        assertEquals("Math", result.get(0).getSubject());
        assertEquals("2026-06-10", result.get(0).getStudyDate());
        assertEquals("09:00", result.get(0).getStartTime());
    }
}

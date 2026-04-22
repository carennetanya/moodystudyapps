package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.ScheduleRequest;
import com.example.moody_study_backend.dto.ScheduleResponse;
import com.example.moody_study_backend.entity.Schedule;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.ScheduleRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;
    private final UserRepository userRepository;

    public ScheduleResponse createSchedule(String email, ScheduleRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        Schedule schedule = Schedule.builder()
                .user(user)
                .subject(request.getSubject())
                .studyDate(LocalDate.parse(request.getStudyDate()))
                .startTime(LocalTime.parse(request.getStartTime()))
                .endTime(LocalTime.parse(request.getEndTime()))
                .location(request.getLocation())
                .mood(request.getMood())
                .isCompleted(false)
                .build();

        scheduleRepository.save(schedule);
        return toResponse(schedule);
    }

    public List<ScheduleResponse> getSchedules(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        return scheduleRepository.findByUserOrderByStudyDateAscStartTimeAsc(user)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public ScheduleResponse completeSchedule(Long id) {
        Schedule schedule = scheduleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Jadwal tidak ditemukan"));

        schedule.setCompleted(true);
        scheduleRepository.save(schedule);
        return toResponse(schedule);
    }

    public void deleteSchedule(Long id) {
        scheduleRepository.deleteById(id);
    }

    private ScheduleResponse toResponse(Schedule s) {
        return new ScheduleResponse(
                s.getId(),
                s.getSubject(),
                s.getStudyDate().toString(),
                s.getStartTime().toString(),
                s.getEndTime().toString(),
                s.getLocation(),
                s.getMood(),
                s.isCompleted()
        );
    }
}
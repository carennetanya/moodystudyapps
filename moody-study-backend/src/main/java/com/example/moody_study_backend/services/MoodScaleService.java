package com.example.moody_study_backend.services;

import com.example.moody_study_backend.entity.MoodScale;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.MoodScaleRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MoodScaleService {

    private final MoodScaleRepository moodScaleRepository;
    private final UserRepository userRepository;

    public MoodScale recordMood(String email, String moodType, int moodValue, String moodFeel, 
                                 int moodIntensity, String moodNote) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        MoodScale moodScale = MoodScale.builder()
                .user(user)
                .moodDate(LocalDateTime.now())
                .moodType(moodType)
                .moodValue(moodValue)
                .moodFeel(moodFeel)
                .moodIntensity(moodIntensity)
                .moodNote(moodNote)
                .build();

        return moodScaleRepository.save(moodScale);
    }

    public List<MoodScale> getUserMoods(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return moodScaleRepository.findByUser(user);
    }

    public List<MoodScale> getMoodsByDateRange(String email, LocalDateTime startDate, LocalDateTime endDate) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return moodScaleRepository.findByUserAndMoodDateBetween(user, startDate, endDate);
    }

    public List<MoodScale> getMoodsByType(String email, String moodType) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return moodScaleRepository.findByUserAndMoodType(user, moodType);
    }
}

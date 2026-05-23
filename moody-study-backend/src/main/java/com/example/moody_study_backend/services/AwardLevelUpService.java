package com.example.moody_study_backend.services;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.example.moody_study_backend.dto.AwardLevelUpResponse;
import com.example.moody_study_backend.dto.AwardProgressResponse;
import com.example.moody_study_backend.entity.AwardLevelUp;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;

@Service
public class AwardLevelUpService {

    // Threshold sesi harus naik level — disesuaikan dengan StreakService
    // Level 1 (Beginner)     : 0–5   sesi  → naik ke Level 2 saat sesi ke-6
    // Level 2 (Learner)      : 6–12  sesi  → naik ke Level 3 saat sesi ke-13
    // Level 3 (Practitioner) : 13–21 sesi  → naik ke Level 4 saat sesi ke-22
    // Level 4 (Expert)       : 22–32 sesi  → naik ke Level 5 saat sesi ke-33
    private static final int[] SESSION_THRESHOLDS = {6, 13, 22, 33};
    private static final int[] XP_REWARDS        = {50, 100, 200, 400};

    private final AwardLevelUpRepository awardLevelUpRepository;
    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;

    public AwardLevelUpService(AwardLevelUpRepository awardLevelUpRepository,
                               StudySessionRepository studySessionRepository,
                               UserRepository userRepository) {
        this.awardLevelUpRepository = awardLevelUpRepository;
        this.studySessionRepository = studySessionRepository;
        this.userRepository = userRepository;
    }

    public List<AwardLevelUpResponse> getAwards(String email) {
        User user = findUserByEmail(email);
        return awardLevelUpRepository.findByUserOrderByLevelAsc(user).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public AwardProgressResponse getProgress(String email) {
        User user = findUserByEmail(email);
        long currentSessionCount = studySessionRepository.countByUser(user);
        int totalXp = awardLevelUpRepository.findByUserOrderByLevelAsc(user).stream()
                .mapToInt(AwardLevelUp::getXpPoints)
                .sum();

        int nextLevelIndex = getNextLevelIndex(user);
        if (nextLevelIndex < 0) {
            return new AwardProgressResponse(currentSessionCount, 0, 0, 0, false, totalXp);
        }

        int nextThreshold = SESSION_THRESHOLDS[nextLevelIndex];
        int nextXpPoints  = XP_REWARDS[nextLevelIndex];
        boolean eligible  = currentSessionCount >= nextThreshold;

        return new AwardProgressResponse(
                currentSessionCount,
                nextLevelIndex + 1,
                nextThreshold,
                nextXpPoints,
                eligible,
                totalXp
        );
    }

    public AwardLevelUpResponse grantAward(String email) {
        User user = findUserByEmail(email);
        long currentSessionCount = studySessionRepository.countByUser(user);
        int nextLevelIndex = getNextLevelIndex(user);

        if (nextLevelIndex < 0) {
            throw new RuntimeException("Semua award sudah diperoleh");
        }

        int requiredThreshold = SESSION_THRESHOLDS[nextLevelIndex];
        if (currentSessionCount < requiredThreshold) {
            throw new RuntimeException(
                "Belum memenuhi syarat award berikutnya. " +
                "Butuh " + requiredThreshold + " sesi, sekarang baru " + currentSessionCount
            );
        }

        AwardLevelUp award = new AwardLevelUp();
        award.setUser(user);
        award.setLevel(nextLevelIndex + 1);
        award.setSummaryCountThreshold(requiredThreshold);
        award.setXpPoints(XP_REWARDS[nextLevelIndex]);
        award.setAwardedAt(LocalDateTime.now());

        return toResponse(awardLevelUpRepository.save(award));
    }

    private User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
    }

    private AwardLevelUpResponse toResponse(AwardLevelUp awardLevelUp) {
        return new AwardLevelUpResponse(
                awardLevelUp.getLevel(),
                awardLevelUp.getSummaryCountThreshold(),
                awardLevelUp.getXpPoints(),
                awardLevelUp.getAwardedAt()
        );
    }

    private int getNextLevelIndex(User user) {
        int currentLevelCount = awardLevelUpRepository.findByUserOrderByLevelAsc(user).size();
        if (currentLevelCount >= SESSION_THRESHOLDS.length) {
            return -1;
        }
        return currentLevelCount;
    }
}
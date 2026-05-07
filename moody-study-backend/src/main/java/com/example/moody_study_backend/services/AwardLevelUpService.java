package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.AwardLevelUpResponse;
import com.example.moody_study_backend.dto.AwardProgressResponse;
import com.example.moody_study_backend.entity.AwardLevelUp;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AwardLevelUpService {

    private static final int[] SUMMARY_THRESHOLDS = {3, 7, 15, 30};
    private static final int[] XP_REWARDS = {50, 100, 200, 400};

    private final AwardLevelUpRepository awardLevelUpRepository;
    private final StudyMaterialRepository studyMaterialRepository;
    private final UserRepository userRepository;

    public AwardLevelUpService(AwardLevelUpRepository awardLevelUpRepository,
                               StudyMaterialRepository studyMaterialRepository,
                               UserRepository userRepository) {
        this.awardLevelUpRepository = awardLevelUpRepository;
        this.studyMaterialRepository = studyMaterialRepository;
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
        long currentSummaryCount = studyMaterialRepository.countCompletedSummariesByUser(user);
        int totalXp = awardLevelUpRepository.findByUserOrderByLevelAsc(user).stream()
                .mapToInt(AwardLevelUp::getXpPoints)
                .sum();

        int nextLevelIndex = getNextLevelIndex(user);
        if (nextLevelIndex < 0) {
            return new AwardProgressResponse(currentSummaryCount, 0, 0, 0, false, totalXp);
        }

        int nextThreshold = SUMMARY_THRESHOLDS[nextLevelIndex];
        int nextXpPoints = XP_REWARDS[nextLevelIndex];
        boolean eligible = currentSummaryCount >= nextThreshold;

        return new AwardProgressResponse(
                currentSummaryCount,
                nextLevelIndex + 1,
                nextThreshold,
                nextXpPoints,
                eligible,
                totalXp
        );
    }

    public AwardLevelUpResponse grantAward(String email) {
        User user = findUserByEmail(email);
        long currentSummaryCount = studyMaterialRepository.countCompletedSummariesByUser(user);
        int nextLevelIndex = getNextLevelIndex(user);

        if (nextLevelIndex < 0) {
            throw new RuntimeException("Semua award sudah diperoleh");
        }

        int requiredThreshold = SUMMARY_THRESHOLDS[nextLevelIndex];
        if (currentSummaryCount < requiredThreshold) {
            throw new RuntimeException("Belum memenuhi syarat award berikutnya");
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
        if (currentLevelCount >= SUMMARY_THRESHOLDS.length) {
            return -1;
        }
        return currentLevelCount;
    }
}

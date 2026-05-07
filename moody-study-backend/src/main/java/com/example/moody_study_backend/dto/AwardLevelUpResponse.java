package com.example.moody_study_backend.dto;

import java.time.LocalDateTime;

public class AwardLevelUpResponse {

    private int level;
    private int summaryCountThreshold;
    private int xpPoints;
    private LocalDateTime awardedAt;

    public AwardLevelUpResponse(int level, int summaryCountThreshold, int xpPoints, LocalDateTime awardedAt) {
        this.level = level;
        this.summaryCountThreshold = summaryCountThreshold;
        this.xpPoints = xpPoints;
        this.awardedAt = awardedAt;
    }

    public int getLevel() {
        return level;
    }

    public void setLevel(int level) {
        this.level = level;
    }

    public int getSummaryCountThreshold() {
        return summaryCountThreshold;
    }

    public void setSummaryCountThreshold(int summaryCountThreshold) {
        this.summaryCountThreshold = summaryCountThreshold;
    }

    public int getXpPoints() {
        return xpPoints;
    }

    public void setXpPoints(int xpPoints) {
        this.xpPoints = xpPoints;
    }

    public LocalDateTime getAwardedAt() {
        return awardedAt;
    }

    public void setAwardedAt(LocalDateTime awardedAt) {
        this.awardedAt = awardedAt;
    }
}

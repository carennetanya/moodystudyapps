package com.example.moody_study_backend.dto;

import java.time.LocalDateTime;

public class AwardLevelUpResponse {

    private int level;
    private int summaryCountThreshold;
    private int coinPoints;
    private LocalDateTime awardedAt;

    public AwardLevelUpResponse(int level, int summaryCountThreshold, int coinPoints, LocalDateTime awardedAt) {
        this.level = level;
        this.summaryCountThreshold = summaryCountThreshold;
        this.coinPoints = coinPoints;
        this.awardedAt = awardedAt;
    }

    public int getLevel() { return level; }
    public void setLevel(int level) { this.level = level; }

    public int getSummaryCountThreshold() { return summaryCountThreshold; }
    public void setSummaryCountThreshold(int summaryCountThreshold) { this.summaryCountThreshold = summaryCountThreshold; }

    public int getCoinPoints() { return coinPoints; }
    public void setCoinPoints(int coinPoints) { this.coinPoints = coinPoints; }

    public LocalDateTime getAwardedAt() { return awardedAt; }
    public void setAwardedAt(LocalDateTime awardedAt) { this.awardedAt = awardedAt; }
}

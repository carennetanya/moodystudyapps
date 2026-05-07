package com.example.moody_study_backend.dto;

public class AwardProgressResponse {

    private long currentSummaryCount;
    private int nextLevel;
    private int nextThreshold;
    private int nextXpPoints;
    private boolean eligible;
    private int totalXp;

    public AwardProgressResponse(long currentSummaryCount, int nextLevel, int nextThreshold, int nextXpPoints, boolean eligible, int totalXp) {
        this.currentSummaryCount = currentSummaryCount;
        this.nextLevel = nextLevel;
        this.nextThreshold = nextThreshold;
        this.nextXpPoints = nextXpPoints;
        this.eligible = eligible;
        this.totalXp = totalXp;
    }

    public long getCurrentSummaryCount() {
        return currentSummaryCount;
    }

    public void setCurrentSummaryCount(long currentSummaryCount) {
        this.currentSummaryCount = currentSummaryCount;
    }

    public int getNextLevel() {
        return nextLevel;
    }

    public void setNextLevel(int nextLevel) {
        this.nextLevel = nextLevel;
    }

    public int getNextThreshold() {
        return nextThreshold;
    }

    public void setNextThreshold(int nextThreshold) {
        this.nextThreshold = nextThreshold;
    }

    public int getNextXpPoints() {
        return nextXpPoints;
    }

    public void setNextXpPoints(int nextXpPoints) {
        this.nextXpPoints = nextXpPoints;
    }

    public boolean isEligible() {
        return eligible;
    }

    public void setEligible(boolean eligible) {
        this.eligible = eligible;
    }

    public int getTotalXp() {
        return totalXp;
    }

    public void setTotalXp(int totalXp) {
        this.totalXp = totalXp;
    }
}

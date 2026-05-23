package com.example.moody_study_backend.dto;

public class AwardProgressResponse {

    private long currentSessionCount; // total sesi belajar user saat ini
    private int nextLevel;
    private int nextThreshold;        // jumlah sesi yang dibutuhkan untuk award berikutnya
    private int nextXpPoints;
    private boolean eligible;
    private int totalXp;

    public AwardProgressResponse(long currentSessionCount, int nextLevel, int nextThreshold,
                                  int nextXpPoints, boolean eligible, int totalXp) {
        this.currentSessionCount = currentSessionCount;
        this.nextLevel = nextLevel;
        this.nextThreshold = nextThreshold;
        this.nextXpPoints = nextXpPoints;
        this.eligible = eligible;
        this.totalXp = totalXp;
    }

    public long getCurrentSessionCount() {
        return currentSessionCount;
    }

    public void setCurrentSessionCount(long currentSessionCount) {
        this.currentSessionCount = currentSessionCount;
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
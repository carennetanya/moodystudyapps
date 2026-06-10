package com.example.moody_study_backend.dto;

public class AwardProgressResponse {

    private long currentSessionCount;
    private int nextLevel;
    private int nextThreshold;
    private int nextCoinPoints;
    private boolean eligible;
    private int totalCoins;

    public AwardProgressResponse(long currentSessionCount, int nextLevel, int nextThreshold,
                                  int nextCoinPoints, boolean eligible, int totalCoins) {
        this.currentSessionCount = currentSessionCount;
        this.nextLevel = nextLevel;
        this.nextThreshold = nextThreshold;
        this.nextCoinPoints = nextCoinPoints;
        this.eligible = eligible;
        this.totalCoins = totalCoins;
    }

    public long getCurrentSessionCount() { return currentSessionCount; }
    public void setCurrentSessionCount(long currentSessionCount) { this.currentSessionCount = currentSessionCount; }

    public int getNextLevel() { return nextLevel; }
    public void setNextLevel(int nextLevel) { this.nextLevel = nextLevel; }

    public int getNextThreshold() { return nextThreshold; }
    public void setNextThreshold(int nextThreshold) { this.nextThreshold = nextThreshold; }

    public int getNextCoinPoints() { return nextCoinPoints; }
    public void setNextCoinPoints(int nextCoinPoints) { this.nextCoinPoints = nextCoinPoints; }

    public boolean isEligible() { return eligible; }
    public void setEligible(boolean eligible) { this.eligible = eligible; }

    public int getTotalCoins() { return totalCoins; }
    public void setTotalCoins(int totalCoins) { this.totalCoins = totalCoins; }
}

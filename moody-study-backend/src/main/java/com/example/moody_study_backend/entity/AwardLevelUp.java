package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "award_level_up")
public class AwardLevelUp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private int level;

    @Column(nullable = false)
    private int summaryCountThreshold;

    @Column(nullable = false)
    private int xpPoints;

    @Column(nullable = false)
    private LocalDateTime awardedAt;

    public AwardLevelUp() {
    }

    public AwardLevelUp(Long id, User user, int level, int summaryCountThreshold, int xpPoints, LocalDateTime awardedAt) {
        this.id = id;
        this.user = user;
        this.level = level;
        this.summaryCountThreshold = summaryCountThreshold;
        this.xpPoints = xpPoints;
        this.awardedAt = awardedAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
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

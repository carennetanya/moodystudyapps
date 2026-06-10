package com.example.moody_study_backend.dto;

import com.example.moody_study_backend.entity.QuestKey;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyQuestResponse {

    private String questDate;
    private int todayCoins;   // Coin yang sudah dikumpul dari quest completed hari ini
    private int maxCoins;     // Total Coin maksimal yang bisa didapat hari ini
    private List<QuestItem> quests;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class QuestItem {
        private Long id;
        private QuestKey questKey;
        private String title;
        private String description;
        private int coinReward;
        private boolean completed;
    }
}

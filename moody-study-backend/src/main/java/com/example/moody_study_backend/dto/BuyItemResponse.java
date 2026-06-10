package com.example.moody_study_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BuyItemResponse {
    private String itemId;
    private int pricePaid;
    private int remainingCoins;
    private String message;
}
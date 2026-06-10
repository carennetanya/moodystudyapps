package com.example.moody_study_backend.dto;

import lombok.Data;

@Data
public class BuyItemRequest {
    /** ID item katalog Flutter, e.g. "h_pink" */
    private String itemId;
    /** Harga item — divalidasi di server agar tidak bisa dimanipulasi client */
    private int price;
}
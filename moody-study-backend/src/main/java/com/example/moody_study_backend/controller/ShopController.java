package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.BuyItemRequest;
import com.example.moody_study_backend.dto.BuyItemResponse;
import com.example.moody_study_backend.dto.CollectionResponse;
import com.example.moody_study_backend.services.ShopService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/shop")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ShopController {

    private final ShopService shopService;

    /**
     * POST /api/shop/buy
     * Beli item dengan coin. Cek saldo, potong coin, simpan ke koleksi.
     * Body: { "itemId": "h_pink", "price": 800 }
     */
    @PostMapping("/buy")
    public ResponseEntity<BuyItemResponse> buyItem(
            @RequestBody BuyItemRequest req,
            Authentication authentication) {
        return ResponseEntity.ok(shopService.buyItem(authentication.getName(), req));
    }

    /**
     * GET /api/shop/collection
     * Ambil daftar itemId yang sudah dimiliki user + saldo coin saat ini.
     */
    @GetMapping("/collection")
    public ResponseEntity<CollectionResponse> getCollection(Authentication authentication) {
        return ResponseEntity.ok(shopService.getCollection(authentication.getName()));
    }
}
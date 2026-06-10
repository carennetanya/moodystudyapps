package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.BuyItemRequest;
import com.example.moody_study_backend.dto.BuyItemResponse;
import com.example.moody_study_backend.dto.CollectionResponse;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserCoin;
import com.example.moody_study_backend.entity.UserItem;
import com.example.moody_study_backend.repository.UserCoinRepository;
import com.example.moody_study_backend.repository.UserItemRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ShopService {

    private final UserRepository userRepository;
    private final UserCoinRepository userCoinRepository;
    private final UserItemRepository userItemRepository;

    // ── Beli item ────────────────────────────────────────────────────────────

    @Transactional
    public BuyItemResponse buyItem(String email, BuyItemRequest req) {
        User user = getUser(email);

        // Cek sudah punya item ini belum
        if (userItemRepository.existsByUserAndItemId(user, req.getItemId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Item sudah dimiliki");
        }

        // Cek & potong coin
        UserCoin userCoin = userCoinRepository.findByUser(user)
                .orElse(UserCoin.builder().user(user).totalCoins(0).build());

        if (req.getPrice() > 0 && userCoin.getTotalCoins() < req.getPrice()) {
            throw new ResponseStatusException(
                HttpStatus.PAYMENT_REQUIRED,
                "Coin tidak cukup. Kamu punya " + userCoin.getTotalCoins() +
                " coin, butuh " + req.getPrice() + " coin."
            );
        }

        // Potong coin (item gratis price=0 tidak dipotong)
        userCoin.setTotalCoins(userCoin.getTotalCoins() - req.getPrice());
        userCoinRepository.save(userCoin);

        // Simpan ke koleksi
        UserItem item = UserItem.builder()
                .user(user)
                .itemId(req.getItemId())
                .pricePaid(req.getPrice())
                .build();
        userItemRepository.save(item);

        return BuyItemResponse.builder()
                .itemId(req.getItemId())
                .pricePaid(req.getPrice())
                .remainingCoins(userCoin.getTotalCoins())
                .message(req.getPrice() == 0 ? "Item berhasil didapatkan!" : "Pembelian berhasil!")
                .build();
    }

    // ── Ambil koleksi + saldo coin ───────────────────────────────────────────

    public CollectionResponse getCollection(String email) {
        User user = getUser(email);

        int totalCoins = userCoinRepository.findByUser(user)
                .map(UserCoin::getTotalCoins)
                .orElse(0);

        List<String> ownedItemIds = userItemRepository
                .findByUserOrderByPurchasedAtDesc(user)
                .stream()
                .map(UserItem::getItemId)
                .collect(Collectors.toList());

        return CollectionResponse.builder()
                .totalCoins(totalCoins)
                .ownedItemIds(ownedItemIds)
                .build();
    }

    // ── Helper ───────────────────────────────────────────────────────────────

    private User getUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User tidak ditemukan"));
    }
}
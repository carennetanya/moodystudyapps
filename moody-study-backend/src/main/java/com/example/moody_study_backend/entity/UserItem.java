package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Item yang sudah dibeli user di Shop.
 * itemId merujuk ke id item di katalog Flutter (e.g. "h_pink", "theme_night").
 */
@Entity
@Table(
    name = "user_items",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "item_id"})
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** ID item katalog, e.g. "h_pink", "theme_night" */
    @Column(name = "item_id", nullable = false)
    private String itemId;

    /** Harga yang dibayar saat pembelian (snapshot) */
    @Column(nullable = false)
    private int pricePaid;

    @CreationTimestamp
    @Column(name = "purchased_at", nullable = false, updatable = false)
    private LocalDateTime purchasedAt;
}
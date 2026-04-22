package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.UpdateAccountRequest;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public Map<String, String> updateAccount(String email, UpdateAccountRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        // Verifikasi password lama
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new RuntimeException("Password saat ini salah");
        }

        // Update email
        if (request.getNewEmail() != null && !request.getNewEmail().isBlank()) {
            if (userRepository.existsByEmail(request.getNewEmail())) {
                throw new RuntimeException("Email sudah digunakan");
            }
            user.setEmail(request.getNewEmail());
        }

        // Update password
        if (request.getNewPassword() != null && !request.getNewPassword().isBlank()) {
            if (request.getNewPassword().length() < 6) {
                throw new RuntimeException("Password minimal 6 karakter");
            }
            user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        }

        userRepository.save(user);
        return Map.of(
                "message", "Akun berhasil diupdate",
                "email", user.getEmail()
        );
    }
}
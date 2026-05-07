package com.example.moody_study_backend.services;

import com.example.moody_study_backend.entity.Stream;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.StreamRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class StreamService {

    private final StreamRepository streamRepository;
    private final UserRepository userRepository;

    public Stream createStream(String email, String streamId, LocalDateTime startTime) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        Stream stream = Stream.builder()
                .user(user)
                .streamId(streamId)
                .startTime(startTime)
                .status("active")
                .build();

        return streamRepository.save(stream);
    }

    public Stream updateStreamStatus(Long streamId, String status, LocalDateTime endTime) {
        Stream stream = streamRepository.findById(streamId)
                .orElseThrow(() -> new RuntimeException("Stream tidak ditemukan"));

        stream.setStatus(status);
        if (endTime != null) {
            stream.setEndTime(endTime);
            stream.setDurationSeconds(
                    java.time.temporal.ChronoUnit.SECONDS.between(stream.getStartTime(), endTime)
            );
        }

        return streamRepository.save(stream);
    }

    public List<Stream> getStreamsForUser(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return streamRepository.findByUser(user);
    }

    public Stream getStream(Long streamId) {
        return streamRepository.findById(streamId)
                .orElseThrow(() -> new RuntimeException("Stream tidak ditemukan"));
    }
}

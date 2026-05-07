package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.Stream;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StreamRepository extends JpaRepository<Stream, Long> {
    List<Stream> findByUser(User user);
    Optional<Stream> findByStreamId(String streamId);
    List<Stream> findByStatus(String status);
}

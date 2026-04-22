package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.SavedFileResponse;
import com.example.moody_study_backend.entity.SavedFile;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.SavedFileRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SavedFileService {

    private final SavedFileRepository savedFileRepository;
    private final UserRepository userRepository;

    public SavedFileResponse saveFile(String email, String fileName,
                                      String fileType, String content) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        SavedFile file = SavedFile.builder()
                .user(user)
                .fileName(fileName)
                .fileType(fileType)
                .content(content)
                .savedAt(LocalDateTime.now())
                .build();

        savedFileRepository.save(file);

        return new SavedFileResponse(
                file.getId(),
                file.getFileName(),
                file.getFileType(),
                file.getContent(),
                file.getSavedAt().toString()
        );
    }

    public List<SavedFileResponse> getFiles(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        return savedFileRepository.findByUserOrderBySavedAtDesc(user)
                .stream()
                .map(f -> new SavedFileResponse(
                        f.getId(),
                        f.getFileName(),
                        f.getFileType(),
                        f.getContent(),
                        f.getSavedAt().toString()
                ))
                .collect(Collectors.toList());
    }

    public void deleteFile(Long id) {
        savedFileRepository.deleteById(id);
    }

    public SavedFileResponse renameFile(Long id, String newFileName) {
        SavedFile file = savedFileRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("File tidak ditemukan"));

        file.setFileName(newFileName);
        savedFileRepository.save(file);

        return new SavedFileResponse(
                file.getId(),
                file.getFileName(),
                file.getFileType(),
                file.getContent(),
                file.getSavedAt().toString()
        );
    }
}
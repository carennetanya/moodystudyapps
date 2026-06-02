package com.example.moody_study_backend.services;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.entity.SavedFile;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.SavedFileRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class SavedFileServiceTest {

    @Mock
    SavedFileRepository savedFileRepository;

    @Mock
    UserRepository userRepository;

    @InjectMocks
    SavedFileService savedFileService;

    @Test
    void saveFile_shouldPersistFile() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(savedFileRepository.save(any(SavedFile.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertEquals("file.txt", savedFileService.saveFile("test@gmail.com", "file.txt", "text", "content").getFileName());
    }
}

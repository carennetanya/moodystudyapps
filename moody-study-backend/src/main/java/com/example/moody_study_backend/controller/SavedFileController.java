package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.SavedFileResponse;
import com.example.moody_study_backend.dto.RenameFileRequest;
import com.example.moody_study_backend.services.SavedFileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SavedFileController {

    private final SavedFileService savedFileService;

    @PostMapping("/save")
    public ResponseEntity<SavedFileResponse> saveFile(
            @RequestBody Map<String, String> body,
            Authentication authentication) {
        return ResponseEntity.ok(
                savedFileService.saveFile(
                        authentication.getName(),
                        body.get("fileName"),
                        body.get("fileType"),
                        body.get("content")
                )
        );
    }

    @GetMapping
    public ResponseEntity<List<SavedFileResponse>> getFiles(Authentication authentication) {
        return ResponseEntity.ok(
                savedFileService.getFiles(authentication.getName())
        );
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFile(@PathVariable Long id) {
        savedFileService.deleteFile(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/rename")
    public ResponseEntity<SavedFileResponse> renameFile(
            @PathVariable Long id,
            @Valid @RequestBody RenameFileRequest request) {
        return ResponseEntity.ok(
                savedFileService.renameFile(id, request.getNewFileName())
        );
    }
}
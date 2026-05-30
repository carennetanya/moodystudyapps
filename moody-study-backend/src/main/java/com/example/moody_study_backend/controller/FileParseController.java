package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.services.FileTextExtractorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

/**
 * POST /api/schedule/parse-file
 *
 * Menerima file PDF / DOCX / TXT / CSV dan mengekstrak daftar mata pelajaran.
 * Dipanggil dari Flutter setelah user upload file di dialog "Asisten Oddy".
 *
 * Request  : multipart/form-data, field name = "file"
 * Response : { "subjects": ["Matematika", "IPA", ...] }
 */
@RestController
@RequestMapping("/api/schedule")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class FileParseController {

    private final FileTextExtractorService extractorService;

    @PostMapping(
        value = "/parse-file",
        consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<?> parseFile(
            @RequestParam("file") MultipartFile file) {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "File kosong"));
        }

        String filename = file.getOriginalFilename() != null
                ? file.getOriginalFilename().toLowerCase()
                : "";

        boolean supported = filename.endsWith(".pdf")
                || filename.endsWith(".docx")
                || filename.endsWith(".txt")
                || filename.endsWith(".csv");

        if (!supported) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Format tidak didukung. Gunakan PDF, DOCX, TXT, atau CSV."));
        }

        // Batas ukuran file: 10 MB
        if (file.getSize() > 10 * 1024 * 1024) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Ukuran file melebihi 10 MB."));
        }

        try {
            List<String> subjects = extractorService.extractSubjects(file);

            if (subjects.isEmpty()) {
                return ResponseEntity.ok(Map.of(
                        "subjects", List.of(),
                        "message", "Tidak ditemukan mata pelajaran di file ini. Coba input manual."
                ));
            }

            return ResponseEntity.ok(Map.of("subjects", subjects));

        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Gagal memproses file: " + e.getMessage()));
        }
    }
}
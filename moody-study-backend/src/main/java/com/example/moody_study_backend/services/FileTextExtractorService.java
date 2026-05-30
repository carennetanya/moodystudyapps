package com.example.moody_study_backend.services;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Mengekstrak daftar mata pelajaran dari file PDF atau DOCX yang diupload user.
 *
 * Strategi parsing:
 *  - Split teks berdasarkan newline, koma, titik koma, atau bullet/nomor
 *  - Filter baris kosong, terlalu pendek (<2 char), atau terlalu panjang (>80 char)
 *  - Bersihkan karakter non-printable dan whitespace berlebih
 *  - Maksimal 50 item hasil untuk mencegah abuse
 */
@Service
public class FileTextExtractorService {

    private static final int MAX_SUBJECTS = 50;
    private static final int MIN_LENGTH   = 2;
    private static final int MAX_LENGTH   = 80;

    /**
     * Entry point — deteksi format lalu ekstrak.
     * @return list mata pelajaran yang bersih
     */
    public List<String> extractSubjects(MultipartFile file) throws IOException {
        String filename = file.getOriginalFilename() != null
                ? file.getOriginalFilename().toLowerCase()
                : "";

        String rawText;
        if (filename.endsWith(".pdf")) {
            rawText = extractFromPdf(file.getInputStream());
        } else if (filename.endsWith(".docx")) {
            rawText = extractFromDocx(file.getInputStream());
        } else {
            // txt / csv — plain UTF-8
            rawText = new String(file.getBytes(), java.nio.charset.StandardCharsets.UTF_8);
        }

        return parseSubjects(rawText);
    }

    // ── PDF ──────────────────────────────────────────────────────────────────

    private String extractFromPdf(InputStream is) throws IOException {
        byte[] data = is.readAllBytes();
        try (PDDocument doc = Loader.loadPDF(data)) {
            PDFTextStripper stripper = new PDFTextStripper();
            return stripper.getText(doc);
        }
    }

    // ── DOCX ─────────────────────────────────────────────────────────────────

    private String extractFromDocx(InputStream is) throws IOException {
        try (XWPFDocument doc = new XWPFDocument(is)) {
            StringBuilder sb = new StringBuilder();
            for (XWPFParagraph p : doc.getParagraphs()) {
                String line = p.getText().trim();
                if (!line.isEmpty()) {
                    sb.append(line).append("\n");
                }
            }
            return sb.toString();
        }
    }

    // ── Parser ────────────────────────────────────────────────────────────────

    private List<String> parseSubjects(String raw) {
        if (raw == null || raw.isBlank()) return new ArrayList<>();

        // Split by newline, comma, semicolon
        String[] tokens = raw.split("[\\n\\r,;]+");

        return Arrays.stream(tokens)
                .map(this::clean)
                .filter(s -> !s.isEmpty())
                .filter(s -> s.length() >= MIN_LENGTH && s.length() <= MAX_LENGTH)
                // Hapus token yang keliatan bukan nama mapel (angka pure, URL, dsb)
                .filter(s -> !s.matches("^\\d+\\.?$"))
                .filter(s -> !s.startsWith("http"))
                .distinct()
                .limit(MAX_SUBJECTS)
                .collect(Collectors.toList());
    }

    /** Bersihkan bullet/nomor di awal, whitespace, dan karakter non-printable */
    private String clean(String s) {
        if (s == null) return "";
        return s
                // Hapus bullet / nomor di awal: "1. ", "- ", "• ", dll
                .replaceAll("^[\\s\\-•*\\d.)+]+\\s*", "")
                // Hapus karakter non-printable
                .replaceAll("[^\\x20-\\x7E\\u00A0-\\uFFFF]", " ")
                // Collapse whitespace
                .replaceAll("\\s{2,}", " ")
                .trim();
    }
}
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
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Mengekstrak daftar mata kuliah dari file PDF / DOCX / TXT / CSV.
 *
 * Strategi:
 *  1. Ekstrak raw text dari file sesuai formatnya.
 *  2. Kirim raw text ke Gemini AI untuk mengidentifikasi nama-nama mata kuliah.
 *  3. Fallback ke parser sederhana jika Gemini gagal.
 */
@Service
public class FileTextExtractorService {

    private static final int MAX_SUBJECTS = 50;
    private static final int MIN_LENGTH   = 2;
    private static final int MAX_LENGTH   = 80;

    private final GeminiService geminiService;

    public FileTextExtractorService(GeminiService geminiService) {
        this.geminiService = geminiService;
    }

    /**
     * Entry point — ekstrak raw text lalu minta Gemini identifikasi mata kuliah.
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

        if (rawText == null || rawText.isBlank()) {
            return new ArrayList<>();
        }

        // Gunakan Gemini untuk ekstrak nama matkul dari raw text
        List<String> geminiResult = geminiService.extractSubjectsFromText(rawText);

        // Jika Gemini berhasil dan hasilnya tidak kosong, pakai itu
        if (!geminiResult.isEmpty()) {
            return geminiResult.stream()
                    .filter(s -> s != null && !s.isBlank())
                    .filter(s -> s.length() >= MIN_LENGTH && s.length() <= MAX_LENGTH)
                    .distinct()
                    .limit(MAX_SUBJECTS)
                    .collect(Collectors.toList());
        }

        // Fallback: parser sederhana jika Gemini gagal
        return parseSubjectsFallback(rawText);
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

    // ── Fallback Parser ───────────────────────────────────────────────────────

    /**
     * Fallback sederhana jika Gemini tidak tersedia.
     * Hanya dipakai jika Gemini gagal — hasilnya mungkin tidak akurat untuk PDF tabel.
     */
    private List<String> parseSubjectsFallback(String raw) {
        if (raw == null || raw.isBlank()) return new ArrayList<>();

        String[] tokens = raw.split("[\\n\\r,;]+");

        return Arrays.stream(tokens)
                .map(this::clean)
                .filter(s -> !s.isEmpty())
                .filter(s -> s.length() >= MIN_LENGTH && s.length() <= MAX_LENGTH)
                .filter(s -> !s.matches("^\\d+\\.?$"))
                .filter(s -> !s.startsWith("http"))
                .distinct()
                .limit(MAX_SUBJECTS)
                .collect(Collectors.toList());
    }

    private String clean(String s) {
        if (s == null) return "";
        return s
                .replaceAll("^[\\s\\-•*\\d.)+]+\\s*", "")
                .replaceAll("[^\\x20-\\x7E\\u00A0-\\uFFFF]", " ")
                .replaceAll("\\s{2,}", " ")
                .trim();
    }
}
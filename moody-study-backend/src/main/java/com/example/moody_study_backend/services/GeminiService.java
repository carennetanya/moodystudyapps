package com.example.moody_study_backend.services;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class GeminiService {

    @Value("${gemini.api.key}")
    private String apiKey;

   private static final String GEMINI_URL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=";
    
    private final RestTemplate restTemplate;

    @Autowired
    public GeminiService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public String summarizeMaterial(String originalText, String fileName) {
        String perFileInstructions = "Gunakan nama file '" + fileName + "' sebagai header dan pisahkan setiap file jika ada lebih dari satu.";
        String prompt = """
                Kamu adalah asisten belajar ahli. Buat ringkasan belajar LENGKAP dan MENDALAM dalam Bahasa Indonesia.

                ATURAN KETAT — WAJIB DIIKUTI:
                1. PISAHKAN ringkasan tiap file dengan header nama file yang jelas
                2. KEDALAMAN ringkasan WAJIB sesuai panjang materi:
                %s
                3. SEMUA konsep penting, definisi, fungsi, nama komponen, penjelasan teknis WAJIB ada di ringkasan
                4. Buang hanya: sapaan, basa-basi, pengulangan identik
                5. Setiap poin: tulis NAMA konsep lalu jelaskan dengan kalimat lengkap
                6. Jika materi berisi kode/struktur/komponen: jelaskan SETIAP item satu per satu

                FORMAT WAJIB per file:
                ## 📄 [Nama File]
                ### 📌 Gambaran Umum
                3-5 kalimat gambaran keseluruhan.
                ### 🔑 Poin Penting
                **[Nama Konsep]**: penjelasan 2-5 kalimat.
                ### ✅ Kesimpulan
                3-5 kalimat takeaway.
                ---
                %s
                """.formatted(perFileInstructions, truncate(originalText, 8000));

        try {
            return callGemini(prompt);
        } catch (Exception e) {
            // Log and return a safe fallback summary to avoid propagating raw errors
            System.err.println("Gemini summarize failed: " + e.getMessage());
            String fallback = "Ringkasan sementara (fallback):\n" + truncate(originalText, 1200);
            return fallback;
        }
    }

    public String generateQuiz(String materialText, String quizType,
                                String difficulty, int questionCount) {
        String typeDesc = quizType.equals("multiple_choice")
                ? "pilihan ganda (A/B/C/D) dengan kunci jawaban"
                : "esai singkat dengan contoh jawaban ideal";

        String diffDesc = switch (difficulty) {
            case "easy"  -> "mudah, cocok untuk pemula";
            case "hard"  -> "sulit, membutuhkan pemahaman mendalam";
            default      -> "sedang, sesuai untuk siswa rata-rata";
        };

        String prompt = """
                You are a teacher who creates high-quality practice questions.
                Based on the material below:

                %s

                Create %d %s with difficulty %s.

                Use the same language as the material for the questions, answers, and explanations. If the material is in English, output in English. If the material is in Indonesian, output in Indonesian. If it is in another language, use that language.

                The output MUST follow this format exactly (JSON array):
                [
                  {
                    "number": 1,
                    "question": "...",
                    "type": "%s",
                    "difficulty": "%s",
                    "options": {"A": "...", "B": "...", "C": "...", "D": "..."},
                    "answer": "A",
                    "explanation": "..."
                  }
                ]

                For essay questions, leave "options" empty and fill "answer" with an ideal sample answer.
                Return only the JSON array, with no extra text.
                """.formatted(
                truncate(materialText, 8000),
                questionCount, typeDesc, diffDesc,
                quizType, difficulty
        );

        return callGemini(prompt);
    }

    public String generateAutoSchedule(String sessionHistoryJson,
                                        String existingSchedules,
                                        int daysAhead) {
        String prompt = """
                Kamu adalah AI penjadwal belajar cerdas. Analisa data berikut:

                HISTORI SESI BELAJAR USER:
                %s

                JADWAL YANG SUDAH ADA:
                %s

                Tugasmu:
                1. Analisa pola belajar user (kapan biasanya belajar, mood favorit, durasi rata-rata).
                2. Buat jadwal belajar optimal untuk %d hari ke depan mulai dari besok.
                3. Hindari konflik dengan jadwal yang sudah ada.
                4. Sesuaikan durasi dan mood dengan kebiasaan user.

                Format output WAJIB seperti ini (JSON array):
                [
                  {
                    "subject": "...",
                    "studyDate": "YYYY-MM-DD",
                    "startTime": "HH:MM",
                    "endTime": "HH:MM",
                    "mood": "...",
                    "location": "...",
                    "reason": "alasan singkat kenapa slot ini dipilih"
                  }
                ]

                Pastikan output hanya JSON array, tanpa teks tambahan apapun.
                """.formatted(sessionHistoryJson, existingSchedules, daysAhead);

        return callGemini(prompt);
    }

    private String callGemini(String prompt) {
        String url = GEMINI_URL + apiKey;

        Map<String, Object> part    = Map.of("text", prompt);
        Map<String, Object> content = Map.of("parts", List.of(part));
        Map<String, Object> body    = Map.of("contents", List.of(content));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

        final int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);

                if (response.getStatusCodeValue() == HttpStatus.OK.value() && response.getBody() != null) {
                    List<?> candidates = (List<?>) response.getBody().get("candidates");
                    if (candidates != null && !candidates.isEmpty()) {
                        Map<?, ?> candidate  = (Map<?, ?>) candidates.get(0);
                        Map<?, ?> contentMap = (Map<?, ?>) candidate.get("content");
                        List<?> parts        = (List<?>) contentMap.get("parts");
                        Map<?, ?> firstPart  = (Map<?, ?>) parts.get(0);
                        return (String) firstPart.get("text");
                    }
                }

                int statusCode = response.getStatusCodeValue();
                if ((statusCode >= 500 || statusCode == 429)) {
                    if (attempt < maxAttempts) {
                        long backoff = 500L * attempt;
                        try { Thread.sleep(backoff); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); }
                        continue;
                    } else {
                        throw new RuntimeException("Gemini returned HTTP " + statusCode);
                    }
                }

            } catch (Exception e) {
                if (attempt < maxAttempts) {
                    long backoff = 500L * attempt;
                    try { Thread.sleep(backoff); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); }
                    continue;
                }
                throw new RuntimeException("Gagal menghubungi Gemini AI: " + e.getMessage());
            }
        }

        throw new RuntimeException("Gemini AI tidak menghasilkan respons setelah beberapa percobaan");
    }

    private String truncate(String text, int maxChars) {
        if (text == null) return "";
        return text.length() <= maxChars ? text : text.substring(0, maxChars) + "...";
    }
}

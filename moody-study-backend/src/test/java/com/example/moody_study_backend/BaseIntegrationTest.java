package com.example.moody_study_backend;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;

import com.example.moody_study_backend.entity.AwardLevelUp;
import com.example.moody_study_backend.entity.GeneratedQuiz;
import com.example.moody_study_backend.entity.Notification;
import com.example.moody_study_backend.entity.SavedFile;
import com.example.moody_study_backend.entity.Schedule;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.SubjectPlan;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserXp;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.DailyQuestRepository;
import com.example.moody_study_backend.repository.GeneratedQuizRepository;
import com.example.moody_study_backend.repository.NotificationRepository;
import com.example.moody_study_backend.repository.SavedFileRepository;
import com.example.moody_study_backend.repository.ScheduleRepository;
import com.example.moody_study_backend.repository.StreakRepository;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.SubjectPlanRepository;
import com.example.moody_study_backend.repository.UserProfileRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.repository.UserXpRepository;
import com.example.moody_study_backend.services.GeminiService;
import com.fasterxml.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(BaseIntegrationTest.IntegrationTestConfig.class)
public abstract class BaseIntegrationTest {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    @Autowired
    protected UserRepository userRepository;

    @Autowired
    protected PasswordEncoder passwordEncoder;

    @Autowired
    protected AwardLevelUpRepository awardLevelUpRepository;

    @Autowired
    protected DailyQuestRepository dailyQuestRepository;

    @Autowired
    protected SubjectPlanRepository subjectPlanRepository;

    @Autowired
    protected ScheduleRepository scheduleRepository;

    @Autowired
    protected NotificationRepository notificationRepository;

    @Autowired
    protected SavedFileRepository savedFileRepository;

    @Autowired
    protected StudyMaterialRepository studyMaterialRepository;

    @Autowired
    protected StudySessionRepository studySessionRepository;

    @Autowired
    protected StreakRepository streakRepository;

    @Autowired
    protected GeneratedQuizRepository generatedQuizRepository;

    @Autowired
    protected UserProfileRepository userProfileRepository;

    @Autowired
    protected UserXpRepository userXpRepository;

    public static PostgreSQLContainer<?> postgres;

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {

        String useTc = System.getenv().getOrDefault(
                "USE_TESTCONTAINERS",
                "true");

        if ("true".equalsIgnoreCase(useTc)) {
            try {

                postgres = new PostgreSQLContainer<>(
                        "postgres:15-alpine")
                        .withDatabaseName(
                                "integration-tests-db")
                        .withUsername("test")
                        .withPassword("test");

                postgres.start();

                registry.add(
                        "spring.datasource.url",
                        postgres::getJdbcUrl);

                registry.add(
                        "spring.datasource.username",
                        postgres::getUsername);

                registry.add(
                        "spring.datasource.password",
                        postgres::getPassword);

                registry.add(
                        "spring.datasource.driver-class-name",
                        () -> "org.postgresql.Driver");

                registry.add(
                        "spring.flyway.enabled",
                        () -> "true");

                return;

            } catch (Throwable t) {
                // fallback ke H2
            }
        }

        registry.add(
                "spring.datasource.url",
                () -> "jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL");

        registry.add(
                "spring.datasource.username",
                () -> "sa");

        registry.add(
                "spring.datasource.password",
                () -> "");

        registry.add(
                "spring.datasource.driver-class-name",
                () -> "org.h2.Driver");

        registry.add(
                "spring.jpa.hibernate.ddl-auto",
                () -> "create-drop");

        registry.add(
                "spring.flyway.enabled",
                () -> "false");
    }

    @BeforeEach
    public void clean() {

        generatedQuizRepository.deleteAllInBatch();
        userProfileRepository.deleteAllInBatch();
        userXpRepository.deleteAllInBatch();
        awardLevelUpRepository.deleteAllInBatch();
        savedFileRepository.deleteAllInBatch();
        studyMaterialRepository.deleteAllInBatch();
        studySessionRepository.deleteAllInBatch();
        notificationRepository.deleteAllInBatch();
        scheduleRepository.deleteAllInBatch();
        streakRepository.deleteAllInBatch();
        dailyQuestRepository.deleteAllInBatch();
        subjectPlanRepository.deleteAllInBatch();
        userRepository.deleteAllInBatch();

        User user = User.builder()
                .email("test@example.com")
                .username("testuser")
                .name("Test User")
                .password(passwordEncoder.encode("password123"))
                .build();

        userRepository.save(user);
    }

    protected SecurityMockMvcRequestPostProcessors.UserRequestPostProcessor authenticatedUser() {
        return user("test@example.com")
                .authorities(
                new SimpleGrantedAuthority("ROLE_USER"));
    }

    protected User testUser() {
        return userRepository.findByEmail("test@example.com")
                .orElseThrow();
    }

    protected StudySession seedStudySession() {
        return studySessionRepository.save(StudySession.builder()
                .user(testUser())
                .mood("focused")
                .location("Perpustakaan")
                .durationMinutes(45)
                .focusSeconds(2400)
                .distractionSeconds(300)
                .startTime(LocalDateTime.now().minusMinutes(45))
                .endTime(LocalDateTime.now())
                .build());
    }

    protected StudyMaterial seedStudyMaterial() {
        return studyMaterialRepository.save(StudyMaterial.builder()
                .user(testUser())
                .fileName("notes.txt")
                .title("notes.txt")
                .originalText("Materi belajar untuk kuis.")
                .summary("Ringkasan test")
                .uploadedAt(LocalDateTime.now())
                .build());
    }

    protected GeneratedQuiz seedGeneratedQuiz(boolean saved) {
        return generatedQuizRepository.save(GeneratedQuiz.builder()
                .user(testUser())
                .material(seedStudyMaterial())
                .quizContent("[{\"number\":1,\"question\":\"Apa itu test?\"}]")
                .generatedAt(LocalDateTime.now())
                .saved(saved)
                .build());
    }

    protected Schedule seedSchedule() {
        return scheduleRepository.save(Schedule.builder()
                .user(testUser())
                .subject("Matematika")
                .studyDate(LocalDate.now().plusDays(1))
                .startTime(LocalTime.of(10, 0))
                .endTime(LocalTime.of(11, 0))
                .location("Rumah")
                .mood("focused")
                .isCompleted(false)
                .build());
    }

    protected Notification seedNotification() {
        return notificationRepository.save(Notification.builder()
                .user(testUser())
                .schedule(seedSchedule())
                .message("Jadwal belajar segera dimulai")
                .isRead(false)
                .createdAt(LocalDateTime.now())
                .build());
    }

    protected SavedFile seedSavedFile() {
        return savedFileRepository.save(SavedFile.builder()
                .user(testUser())
                .fileName("notes.txt")
                .fileType("txt")
                .content("isi file")
                .savedAt(LocalDateTime.now())
                .build());
    }

    protected SubjectPlan seedSubjectPlan() {
        return subjectPlanRepository.save(SubjectPlan.builder()
                .user(testUser())
                .subject("Fisika")
                .description("Rencana belajar fisika")
                .startDate(LocalDate.now())
                .endDate(LocalDate.now().plusDays(7))
                .targetHours(10)
                .completedHours(0)
                .status("active")
                .build());
    }

    protected AwardLevelUp seedAward(int level) {
        AwardLevelUp award = new AwardLevelUp();
        award.setUser(testUser());
        award.setLevel(level);
        award.setSummaryCountThreshold(6);
        award.setXpPoints(50);
        award.setAwardedAt(LocalDateTime.now());
        return awardLevelUpRepository.save(award);
    }

    protected UserXp seedUserXp(int totalXp) {
        return userXpRepository.save(UserXp.builder()
                .user(testUser())
                .totalXp(totalXp)
                .build());
    }

    @TestConfiguration
    static class IntegrationTestConfig {

        @Bean
        @Primary
        GeminiService geminiServiceStub() {
            return new GeminiService(null) {
                @Override
                public String summarizeMaterial(String originalText, String fileName) {
                    return "Ringkasan test untuk " + fileName;
                }

                @Override
                public String generateQuiz(String materialText, String quizType, String difficulty, int questionCount) {
                    return "[{\"number\":1,\"question\":\"Apa inti materi?\",\"type\":\""
                            + quizType + "\",\"difficulty\":\"" + difficulty
                            + "\",\"options\":{\"A\":\"A\",\"B\":\"B\",\"C\":\"C\",\"D\":\"D\"},\"answer\":\"A\",\"explanation\":\"Test\"}]";
                }

                @Override
                public List<String> extractSubjectsFromText(String rawText) {
                    return List.of("Matematika", "IPA");
                }

                @Override
                public String generateAutoSchedule(String sessionHistoryJson, String existingSchedules,
                                                   int daysAhead, String additionalInstructions) {
                    return """
                            [{
                              "subject":"Matematika",
                              "studyDate":"2026-06-03",
                              "startTime":"10:00",
                              "endTime":"11:30",
                              "location":"Rumah",
                              "mood":"focused"
                            }]
                            """;
                }
            };
        }
    }
}

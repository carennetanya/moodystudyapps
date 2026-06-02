package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.entity.GeneratedQuiz;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.Role;
import com.example.moody_study_backend.repository.GeneratedQuizRepository;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.time.LocalDateTime;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Testcontainers
@Transactional
class ControllerIntegrationTest {

    private static final String TEST_EMAIL = "test@example.com";
    private static final String TEST_USERNAME = "testuser";
    private static final String TEST_PASSWORD = "Password123";

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15.4")
            .withDatabaseName("test_db")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void registerDatabaseProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.datasource.driver-class-name", postgres::getDriverClassName);
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StudyMaterialRepository studyMaterialRepository;

    @Autowired
    private GeneratedQuizRepository generatedQuizRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        generatedQuizRepository.deleteAll();
        studyMaterialRepository.deleteAll();
        createUser(TEST_EMAIL, TEST_USERNAME, TEST_PASSWORD);
    }

    @Test
    void registerShouldReturnAuthResponse() throws Exception {
        Map<String, String> request = Map.of(
                "username", "newuser",
                "name", "New User",
                "email", "newuser@example.com",
                "password", "secret123"
        );

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("newuser@example.com"))
                .andExpect(jsonPath("$.token").isString());
    }

    @Test
    void registerShouldReturnBadRequestWhenEmailIsInvalid() throws Exception {
        Map<String, String> request = Map.of(
                "username", "newuser",
                "name", "New User",
                "email", "invalid-email",
                "password", "secret123"
        );

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void getProfileShouldReturnUserDetails() throws Exception {
        mockMvc.perform(get("/api/user/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(TEST_EMAIL))
                .andExpect(jsonPath("$.role").value("ROLE_USER"));
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void updateAccountShouldChangeEmailWhenCurrentPasswordMatches() throws Exception {
        Map<String, String> request = Map.of(
                "newEmail", "updated@example.com",
                "currentPassword", TEST_PASSWORD
        );

        mockMvc.perform(patch("/api/user/update")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("updated@example.com"));
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void getUserInfoShouldReturnProfileInfo() throws Exception {
        mockMvc.perform(get("/api/profile/info"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(TEST_EMAIL))
                .andExpect(jsonPath("$.username").value(TEST_USERNAME));
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void updateNameShouldReturnUpdatedName() throws Exception {
        Map<String, String> request = Map.of("name", "Updated Name");

        mockMvc.perform(post("/api/profile/update-name")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated Name"));
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void createScheduleShouldPersistAndReturnExpectedFields() throws Exception {
        Map<String, String> request = Map.of(
                "subject", "Math",
                "studyDate", "2025-01-01",
                "startTime", "09:00",
                "endTime", "10:00",
                "location", "Library",
                "mood", "Focused"
        );

        mockMvc.perform(post("/api/schedule")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.subject").value("Math"))
                .andExpect(jsonPath("$.studyDate").value("2025-01-01"));
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void completeScheduleShouldMarkCompletedAndDeleteShouldReturnNoContent() throws Exception {
        Map<String, String> scheduleRequest = Map.of(
                "subject", "Science",
                "studyDate", "2025-01-01",
                "startTime", "11:00",
                "endTime", "12:00",
                "location", "Room 101",
                "mood", "Curious"
        );

        String content = mockMvc.perform(post("/api/schedule")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(scheduleRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isCompleted").value(false))
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long scheduleId = objectMapper.readTree(content).get("id").asLong();

        mockMvc.perform(patch("/api/schedule/" + scheduleId + "/complete"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isCompleted").value(true));

        mockMvc.perform(delete("/api/schedule/" + scheduleId))
                .andExpect(status().isNoContent());
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void createMoodLogShouldReturnMoodLogAndFetchBySubject() throws Exception {
        Map<String, Object> request = Map.of(
                "subject", "Health",
                "moodFeel", "Happy",
                "moodIntensity", 7,
                "notes", "Kept my focus"
        );

        mockMvc.perform(post("/api/mood-logs/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.subject").value("Health"));

        mockMvc.perform(get("/api/mood-logs/subject/Health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].moodFeel").value("Happy"));
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void dailyQuestEndpointsShouldReturnDailyQuestsAndCompleteReview() throws Exception {
        mockMvc.perform(get("/api/quest/daily"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quests.length()").value(3));

        mockMvc.perform(post("/api/quest/complete-review"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.todayXp").isNumber());
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void streakEndpointsShouldReturnCurrentStreakAndCompleteSession() throws Exception {
        mockMvc.perform(get("/api/streak"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentStreak").isNumber());

        Map<String, Object> request = Map.of(
                "mood", "Motivated",
                "location", "Desk",
                "durationMinutes", 30,
                "focusSeconds", 1500,
                "distractionSeconds", 0
        );

        mockMvc.perform(post("/api/streak/complete")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentStreak").value(1));
    }

    @Test
    @WithMockUser(username = TEST_EMAIL, roles = {"USER"})
    void generatedQuizEndpointsShouldReturnSavedQuizAndDetail() throws Exception {
        StudyMaterial material = StudyMaterial.builder()
                .user(createUser("quizuser@example.com", "quizuser", TEST_PASSWORD))
                .title("Sample Material")
                .fileName("sample.txt")
                .originalText("Question text")
                .summary("A short summary")
                .uploadedAt(LocalDateTime.now())
                .build();
        studyMaterialRepository.save(material);

        GeneratedQuiz quiz = GeneratedQuiz.builder()
                .user(userRepository.findByEmail(TEST_EMAIL).orElseThrow())
                .material(material)
                .quizContent("Sample quiz content")
                .generatedAt(LocalDateTime.now())
                .saved(true)
                .build();
        generatedQuizRepository.save(quiz);

        mockMvc.perform(get("/api/quiz"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].quizContent").value("Sample quiz content"));

        mockMvc.perform(get("/api/quiz/saved"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].saved").value(true));

        mockMvc.perform(get("/api/quiz/" + quiz.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(quiz.getId()));
    }

    private User createUser(String email, String username, String rawPassword) {
        User user = User.builder()
                .email(email)
                .username(username)
                .name("Test Name")
                .password(passwordEncoder.encode(rawPassword))
                .role(Role.ROLE_USER)
                .build();
        return userRepository.save(user);
    }
}

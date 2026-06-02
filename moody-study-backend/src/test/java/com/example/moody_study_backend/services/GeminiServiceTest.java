package com.example.moody_study_backend.services;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@ExtendWith(MockitoExtension.class)
class GeminiServiceTest {

    @Mock
    RestTemplate restTemplate;

    @InjectMocks
    GeminiService geminiService;

    @SuppressWarnings("unchecked")
    @Test
    void summarizeMaterial_shouldReturnFallbackWhenGeminiFails() {
        when(restTemplate.exchange(anyString(), any(HttpMethod.class), any(HttpEntity.class), any(ParameterizedTypeReference.class)))
                .thenThrow(new RestClientException("timeout"));

        String fallback = geminiService.summarizeMaterial("Hello world", "notes.txt");

        assertTrue(fallback.startsWith("Ringkasan sementara"));
    }
}

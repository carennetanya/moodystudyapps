package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.entity.SubjectPlan;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.SubjectPlanRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class SubjectPlanServiceTest {

    @Mock
    SubjectPlanRepository subjectPlanRepository;

    @Mock
    UserRepository userRepository;

    @InjectMocks
    SubjectPlanService subjectPlanService;

    @Test
    void createSubjectPlan_shouldPersistSubjectPlan() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(subjectPlanRepository.save(any(SubjectPlan.class))).thenAnswer(invocation -> invocation.getArgument(0));

        SubjectPlan plan = subjectPlanService.createSubjectPlan("test@gmail.com", "Math", "desc", LocalDate.now(), LocalDate.now().plusDays(7), 10);

        assertEquals("Math", plan.getSubject());
    }
}

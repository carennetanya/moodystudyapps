package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.entity.Stream;
import com.example.moody_study_backend.services.StreamService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/streams")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StreamController {

    private final StreamService streamService;

    @PostMapping("/create")
    public ResponseEntity<Stream> createStream(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {
        String streamId = (String) request.get("streamId");
        LocalDateTime startTime = LocalDateTime.parse((String) request.get("startTime"));
        
        Stream stream = streamService.createStream(authentication.getName(), streamId, startTime);
        return ResponseEntity.ok(stream);
    }

    @PutMapping("/{streamId}/status")
    public ResponseEntity<Stream> updateStreamStatus(
            @PathVariable Long streamId,
            @RequestBody Map<String, Object> request) {
        String status = (String) request.get("status");
        String endTimeStr = (String) request.get("endTime");
        LocalDateTime endTime = endTimeStr != null ? LocalDateTime.parse(endTimeStr) : null;
        
        Stream stream = streamService.updateStreamStatus(streamId, status, endTime);
        return ResponseEntity.ok(stream);
    }

    @GetMapping
    public ResponseEntity<List<Stream>> getUserStreams(Authentication authentication) {
        List<Stream> streams = streamService.getStreamsForUser(authentication.getName());
        return ResponseEntity.ok(streams);
    }

    @GetMapping("/{streamId}")
    public ResponseEntity<Stream> getStream(@PathVariable Long streamId) {
        Stream stream = streamService.getStream(streamId);
        return ResponseEntity.ok(stream);
    }
}

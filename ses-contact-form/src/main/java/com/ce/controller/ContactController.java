package com.ce.controller;

import com.ce.model.ContactMessage;
import com.ce.model.ContactResponse;
import com.ce.service.ContactEmailService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class ContactController {

    private final ContactEmailService emailService;

    public ContactController(ContactEmailService emailService) {
        this.emailService = emailService;
    }

    /**
     * POST /api/contact  ->  200 {"status":"SENT","messageId":"..."} | 400 problem+json | 502 problem+json
     */
    @PostMapping("/contact")
    public ResponseEntity<ContactResponse> send(@Valid @RequestBody ContactMessage message) {
        String messageId = emailService.send(message);
        return ResponseEntity.ok(new ContactResponse("SENT", messageId));
    }

    /**
     * GET /api/health - cheap liveness check that does not touch SES.
     */
    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("Status", "UP");
    }
}

package com.ce.config;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import java.util.List;

/**
 * Bound from environment variables set by Terraform
 * (SES_FROM_ADDRESS, SES_RECIPIENT_ADDRESS, SES_CONFIGURATION_SET, CORS_ALLOWED_ORIGINS).
 * The app fails fast at startup when a required value is missing.
 */
@Validated
@ConfigurationProperties(prefix = "contact")
public record ContactProperties(
        @NotBlank @Email String fromAddress,
        @NotBlank @Email String recipientAddress,
        String configurationSet,
        List<String> allowedOrigins) {

    public ContactProperties {
        allowedOrigins = allowedOrigins == null ? List.of()
                : allowedOrigins.stream().map(String::trim).filter(o -> !o.isEmpty()).toList();
    }
}

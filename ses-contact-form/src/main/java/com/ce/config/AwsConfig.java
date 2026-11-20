package com.ce.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.core.client.config.ClientOverrideConfiguration;
import software.amazon.awssdk.services.sesv2.SesV2Client;

import java.time.Duration;

@Configuration
public class AwsConfig {

    /**
     * No credentials in code: the default provider chain picks up the Lambda execution role
     * (and keeps working after a SnapStart restore). The region comes from AWS_REGION.
     */
    @Bean(destroyMethod = "close")
    public SesV2Client sesV2Client() {
        return SesV2Client.builder()
                .httpClientBuilder(UrlConnectionHttpClient.builder())
                .overrideConfiguration(ClientOverrideConfiguration.builder()
                        .apiCallTimeout(Duration.ofSeconds(10))
                        .apiCallAttemptTimeout(Duration.ofSeconds(5))
                        .build())
                .build();
    }
}

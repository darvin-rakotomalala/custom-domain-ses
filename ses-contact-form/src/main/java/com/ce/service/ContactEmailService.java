package com.ce.service;

import com.ce.config.ContactProperties;
import com.ce.exception.EmailDeliveryException;
import com.ce.model.ContactMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import software.amazon.awssdk.core.exception.SdkException;
import software.amazon.awssdk.services.sesv2.SesV2Client;
import software.amazon.awssdk.services.sesv2.model.Body;
import software.amazon.awssdk.services.sesv2.model.Content;
import software.amazon.awssdk.services.sesv2.model.Destination;
import software.amazon.awssdk.services.sesv2.model.EmailContent;
import software.amazon.awssdk.services.sesv2.model.Message;
import software.amazon.awssdk.services.sesv2.model.SendEmailRequest;
import software.amazon.awssdk.services.sesv2.model.SendEmailResponse;

@Service
public class ContactEmailService {

    private static final Logger log = LoggerFactory.getLogger(ContactEmailService.class);
    private static final String CHARSET = "UTF-8";
    private static final String FROM_DISPLAY_NAME = "Website Contact Form";

    private final SesV2Client ses;
    private final ContactProperties properties;

    public ContactEmailService(SesV2Client ses, ContactProperties properties) {
        this.ses = ses;
        this.properties = properties;
    }

    /**
     * Emails the visitor's message to the site owner.
     *
     * <p>The message is always sent FROM the verified domain address. The visitor's address only goes
     * in Reply-To, so SES never sends on behalf of an unverified identity and DMARC stays aligned.
     *
     * @return the SES message id
     */
    public String send(ContactMessage message) {
        SendEmailRequest.Builder request = SendEmailRequest.builder()
                .fromEmailAddress(FROM_DISPLAY_NAME + " <" + properties.fromAddress() + ">")
                .destination(Destination.builder().toAddresses(properties.recipientAddress()).build())
                .replyToAddresses(message.senderEmail())
                .content(EmailContent.builder()
                        .simple(Message.builder()
                                .subject(utf8("[Contact Form] " + message.senderSubject()))
                                .body(Body.builder().text(utf8(buildBody(message))).build())
                                .build())
                        .build());

        if (StringUtils.hasText(properties.configurationSet())) {
            request.configurationSetName(properties.configurationSet());
        }

        try {
            SendEmailResponse response = ses.sendEmail(request.build());
            log.info("Contact message sent via SES, messageId={}", response.messageId());
            return response.messageId();
        } catch (SdkException e) {
            // Do not log the visitor's message/email (PII); the SDK error is enough for diagnosis.
            log.error("SES sendEmail failed: {}", e.getMessage(), e);
            throw new EmailDeliveryException("Unable to send the message at the moment", e);
        }
    }

    private static String buildBody(ContactMessage m) {
        // Plain text only: nothing the visitor typed is ever interpreted as HTML.
        return """
                New message from the website contact form
                
                Name:    %s
                Email:   %s
                Subject: %s
                
                Message:
                %s
                """.formatted(m.senderName(), m.senderEmail(), m.senderSubject(), m.senderMessage());
    }

    private static Content utf8(String data) {
        return Content.builder().data(data).charset(CHARSET).build();
    }
}

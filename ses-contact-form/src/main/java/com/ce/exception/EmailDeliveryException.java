package com.ce.exception;

/**
 * Raised when SES could not accept the message.
 */
public class EmailDeliveryException extends RuntimeException {

    public EmailDeliveryException(String message, Throwable cause) {
        super(message, cause);
    }
}

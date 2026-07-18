package com.winwintravel.authapi.process;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "processing_log")
public class ProcessingLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String userEmail;

    @Column(name = "input_text", length = 2000)
    private String inputText;

    @Column(name = "output_text", length = 2000)
    private String outputText;

    private Instant createdAt = Instant.now();

    public Long getId() {
        return id;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public String getInputText() {
        return inputText;
    }

    public void setInputText(String inputText) {
        this.inputText = inputText;
    }

    public String getOutputText() {
        return outputText;
    }

    public void setOutputText(String outputText) {
        this.outputText = outputText;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}

package com.winwintravel.authapi.process;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "processinglog")
public class ProcessingLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_email", length = 255)
    private String userEmail;

    @Column(name = "input_text", nullable = false, columnDefinition = "TEXT")
    private String inputText;

    @Column(name = "output_text", nullable = false, columnDefinition = "TEXT")
    private String outputText;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public Long getId() { return id; }
    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }
    public String getInputText() { return inputText; }
    public void setInputText(String inputText) { this.inputText = inputText; }
    public String getOutputText() { return outputText; }
    public void setOutputText(String outputText) { this.outputText = outputText; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

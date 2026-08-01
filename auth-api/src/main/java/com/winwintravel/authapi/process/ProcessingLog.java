package com.winwintravel.authapi.process;

import com.winwintravel.authapi.user.User;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "processinglog")
public class ProcessingLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "input_text", nullable = false, columnDefinition = "TEXT")
    private String inputText;

    @Column(name = "output_text", nullable = false, columnDefinition = "TEXT")
    private String outputText;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public Long getId() { return id; }

    public User getUser() { return user; }

    public void setUser(User user) { this.user = user; }

    public String getInputText() { return inputText; }

    public void setInputText(String inputText) { this.inputText = inputText; }

    public String getOutputText() { return outputText; }

    public void setOutputText(String outputText) { this.outputText = outputText; }

    public Instant getCreatedAt() { return createdAt; }

    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

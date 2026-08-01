package com.winwintravel.authapi.process;

import com.winwintravel.authapi.user.User;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "processinglog")
public class ProcessingLog {

    @PrePersist
    public void prePersist() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "user_email", nullable = false, length = 255)
    private String userEmail;

    @Column(name = "input_text", nullable = false)
    private String inputText;

    @Column(name = "output_text", nullable = false)
    private String outputText;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public String getInputText() { return inputText; }
    public void setInputText(String inputText) { this.inputText = inputText; }

    public String getOutputText() { return outputText; }
    public void setOutputText(String outputText) { this.outputText = outputText; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}


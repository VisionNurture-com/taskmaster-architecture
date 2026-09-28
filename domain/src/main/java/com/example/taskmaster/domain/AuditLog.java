package com.example.taskmaster.domain;

import java.time.Instant;

/** 監査ログ（006）。何をしたかと、どのタスクに対してかだけを持つ */
public class AuditLog {

    private final Long id;
    private final String action;
    private final Long taskId;
    private final Instant loggedAt;

    public AuditLog(String action, Long taskId) {
        this(null, action, taskId, Instant.now());
    }

    public AuditLog(Long id, String action, Long taskId, Instant loggedAt) {
        this.id = id;
        this.action = action;
        this.taskId = taskId;
        this.loggedAt = loggedAt;
    }

    public Long getId() { return id; }
    public String getAction() { return action; }
    public Long getTaskId() { return taskId; }
    public Instant getLoggedAt() { return loggedAt; }
}

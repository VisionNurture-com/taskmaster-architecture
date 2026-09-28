package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.AuditLog;
import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "audit_logs")
class AuditLogJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String action;

    @Column(name = "task_id")
    private Long taskId;

    @Column(name = "logged_at", nullable = false)
    private Instant loggedAt;

    protected AuditLogJpaEntity() {}

    static AuditLogJpaEntity fromDomain(AuditLog log) {
        AuditLogJpaEntity entity = new AuditLogJpaEntity();
        entity.id = log.getId();
        entity.action = log.getAction();
        entity.taskId = log.getTaskId();
        entity.loggedAt = log.getLoggedAt();
        return entity;
    }

    AuditLog toDomain() {
        return new AuditLog(id, action, taskId, loggedAt);
    }
}

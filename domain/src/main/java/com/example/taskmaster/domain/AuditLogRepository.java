package com.example.taskmaster.domain;

public interface AuditLogRepository {

    AuditLog save(AuditLog log);

    long count();
}

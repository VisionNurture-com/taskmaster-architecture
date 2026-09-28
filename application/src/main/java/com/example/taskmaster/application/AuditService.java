package com.example.taskmaster.application;

import com.example.taskmaster.domain.AuditLog;
import com.example.taskmaster.domain.AuditLogRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public AuditService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void logAction(String action, Long taskId) {
        AuditLog log = new AuditLog(action, taskId);
        auditLogRepository.save(log);
    }
}

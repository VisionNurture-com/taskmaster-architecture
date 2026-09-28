package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.AuditLog;
import com.example.taskmaster.domain.AuditLogRepository;
import org.springframework.stereotype.Repository;

@Repository
public class JpaAuditLogRepository implements AuditLogRepository {

    private final SpringDataAuditLogRepository springDataRepository;

    public JpaAuditLogRepository(SpringDataAuditLogRepository springDataRepository) {
        this.springDataRepository = springDataRepository;
    }

    @Override
    public AuditLog save(AuditLog log) {
        return springDataRepository.save(AuditLogJpaEntity.fromDomain(log)).toDomain();
    }

    @Override
    public long count() {
        return springDataRepository.count();
    }
}

package com.example.taskmaster.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

interface SpringDataAuditLogRepository extends JpaRepository<AuditLogJpaEntity, Long> {
}

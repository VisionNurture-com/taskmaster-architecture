package com.example.taskmaster.infrastructure;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

// 測定用（記事には載せない）。R12: 接続が 1 本のプールで REQUIRES_NEW を入れ子にしたときの例外
@SpringBootTest(classes = InfraTestApplication.class, properties = {
        "spring.jpa.hibernate.ddl-auto=create",
        "spring.datasource.hikari.maximum-pool-size=1",
        "spring.datasource.hikari.connection-timeout=1000"})
@Testcontainers
class PoolExhaustionProbeTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:17-alpine");

    @Autowired SpringDataTaskRepository repo;
    @Autowired PlatformTransactionManager tm;

    @Test
    void r12() {
        TransactionTemplate outer = new TransactionTemplate(tm);
        TransactionTemplate inner = new TransactionTemplate(tm);
        inner.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        try {
            outer.executeWithoutResult(st -> {
                repo.count();
                inner.executeWithoutResult(st2 -> repo.count());
            });
            ProbeSupport.print("R12_result", "no-exception");
        } catch (RuntimeException e) {
            ProbeSupport.print("R12_exception", e.getClass().getName());
            Throwable root = e;
            while (root.getCause() != null) root = root.getCause();
            ProbeSupport.print("R12_rootCause", root.getClass().getName() + ": " + root.getMessage());
        }
    }
}

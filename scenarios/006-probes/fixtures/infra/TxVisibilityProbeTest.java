package com.example.taskmaster.infrastructure;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

// 測定用（記事には載せない）
@SpringBootTest(classes = InfraTestApplication.class, properties = "spring.jpa.hibernate.ddl-auto=create")
@Testcontainers
class TxVisibilityProbeTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:17-alpine");

    @Autowired TxVisibilityProbe probe;

    @Test
    void r11() {
        ProbeSupport.print("R11_proxyClass", probe.getClass().getSimpleName().replaceAll("\\$\\$.*", "\\$\\$…"));
        ProbeSupport.print("R11_public", probe.publicMethod());
        ProbeSupport.print("R11_packagePrivate", probe.packagePrivateMethod());
        ProbeSupport.print("R11_protected", probe.protectedMethod());
    }
}

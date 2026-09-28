package com.example.taskmaster.infrastructure;

import jakarta.persistence.EntityManagerFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import java.util.List;

// 測定用（記事には載せない）。R4: default_batch_fetch_size = 100 で、N = 10 と N = 250 のときのクエリ数
@SpringBootTest(classes = InfraTestApplication.class, properties = {
        "spring.jpa.hibernate.ddl-auto=create",
        "spring.jpa.properties.hibernate.generate_statistics=true",
        "spring.jpa.properties.hibernate.default_batch_fetch_size=100",
        "spring.jpa.show-sql=true"})
@Testcontainers
class BatchSizeProbeTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:17-alpine");

    @Autowired SpringDataTaskRepository repo;
    @Autowired EntityManagerFactory emf;
    @Autowired PlatformTransactionManager tm;

    @Test
    void r4() {
        TransactionTemplate tx = new TransactionTemplate(tm);
        ProbeSupport.seed(tx, emf, 250);
        List<Long> first10 = tx.execute(st -> repo.findAll().stream().map(t -> ProbeSupport.id(t)).sorted().limit(10).toList());
        Statistics s = ProbeSupport.stats(emf);

        s.clear();
        tx.executeWithoutResult(st -> repo.findAllById(first10).forEach(t -> t.getTags().size()));
        ProbeSupport.print("R4_batch100_N10", s.getPrepareStatementCount());

        s.clear();
        tx.executeWithoutResult(st -> repo.findAll().forEach(t -> t.getTags().size()));
        ProbeSupport.print("R4_batch100_N250", s.getPrepareStatementCount());
    }
}

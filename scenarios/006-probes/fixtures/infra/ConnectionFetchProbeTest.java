package com.example.taskmaster.infrastructure;

import com.zaxxer.hikari.HikariDataSource;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import javax.sql.DataSource;

// 測定用（記事には載せない）。R7: SQL を出さないトランザクションの中で、Hikari の使用中の接続の数
@Testcontainers
class ConnectionFetchProbeTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:17-alpine");

    static void probe(String label, DataSource dataSource, PlatformTransactionManager tm, SpringDataTaskRepository repo) throws Exception {
        HikariDataSource hikari = dataSource.unwrap(HikariDataSource.class);
        TransactionTemplate tx = new TransactionTemplate(tm);
        ProbeSupport.print("R7_" + label + "_dataSourceClass", dataSource.getClass().getSimpleName());
        tx.executeWithoutResult(st -> ProbeSupport.print("R7_" + label + "_activeBeforeSql", hikari.getHikariPoolMXBean().getActiveConnections()));
        tx.executeWithoutResult(st -> { repo.count(); ProbeSupport.print("R7_" + label + "_activeAfterSql", hikari.getHikariPoolMXBean().getActiveConnections()); });
    }

    @Nested
    @SpringBootTest(classes = InfraTestApplication.class, properties = {"spring.jpa.hibernate.ddl-auto=create", "spring.datasource.connection-fetch=eager"})
    class Eager {
        @Autowired DataSource dataSource; @Autowired PlatformTransactionManager tm; @Autowired SpringDataTaskRepository repo;
        @Test void eager() throws Exception { probe("eager", dataSource, tm, repo); }
    }

    @Nested
    @SpringBootTest(classes = InfraTestApplication.class, properties = {"spring.jpa.hibernate.ddl-auto=create", "spring.datasource.connection-fetch=lazy"})
    class Lazy {
        @Autowired DataSource dataSource; @Autowired PlatformTransactionManager tm; @Autowired SpringDataTaskRepository repo;
        @Test void lazy() throws Exception { probe("lazy", dataSource, tm, repo); }
    }
}

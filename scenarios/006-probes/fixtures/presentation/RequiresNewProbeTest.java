package com.example.taskmaster.presentation;

import com.example.taskmaster.application.AuditService;
import com.example.taskmaster.application.NotificationService;
import com.example.taskmaster.application.TaskManagementFacade;
import com.example.taskmaster.application.TaskRequest;
import com.example.taskmaster.application.TaskService;
import com.example.taskmaster.domain.AuditLogRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import java.time.LocalDate;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.doThrow;

// 測定用（記事には載せない）。R6: REQUIRES_NEW の監査ログは、外側のトランザクションがロールバックしても残るか
@SpringBootTest(properties = "spring.jpa.hibernate.ddl-auto=create")
@Testcontainers
class RequiresNewProbeTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:17-alpine");

    @Autowired TaskService taskService;
    @Autowired AuditService auditService;
    @Autowired AuditLogRepository auditLogRepository;
    @Autowired TaskManagementFacade facade;
    @Autowired PlatformTransactionManager tm;
    @MockitoBean NotificationService notificationService;

    @Test
    void r6() {
        // a: 監査ログを書いたあとで外側が失敗する
        Long a = taskService.create(new TaskRequest("a", null, LocalDate.of(2026, 6, 1))).id();
        long auditBefore = auditLogRepository.count();
        try {
            new TransactionTemplate(tm).executeWithoutResult(st -> {
                taskService.completeTask(a);
                auditService.logAction("COMPLETE", a);
                throw new IllegalStateException("外側を失敗させる");
            });
        } catch (IllegalStateException expected) {
        }
        System.out.println("PROBE R6a_taskStatusAfterRollback=" + taskService.findById(a).status());
        System.out.println("PROBE R6a_auditLogsAdded=" + (auditLogRepository.count() - auditBefore));

        // b: 記事のファサードで、通知が例外を投げる（監査ログより前）
        Long b = taskService.create(new TaskRequest("b", null, LocalDate.of(2026, 6, 1))).id();
        doThrow(new IllegalStateException("通知の失敗")).when(notificationService).notifyCompletion(anyLong());
        long auditBeforeB = auditLogRepository.count();
        try {
            facade.completeTaskWithNotification(b);
        } catch (IllegalStateException expected) {
        }
        System.out.println("PROBE R6b_taskStatusAfterRollback=" + taskService.findById(b).status());
        System.out.println("PROBE R6b_auditLogsAdded=" + (auditLogRepository.count() - auditBeforeB));
    }
}

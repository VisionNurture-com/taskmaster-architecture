package com.example.taskmaster.application;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TaskManagementFacade {

    private final TaskService taskService;
    private final NotificationService notificationService;
    private final AuditService auditService;

    public TaskManagementFacade(TaskService taskService,
                                NotificationService notificationService,
                                AuditService auditService) {
        this.taskService = taskService;
        this.notificationService = notificationService;
        this.auditService = auditService;
    }

    @Transactional
    public TaskResponse completeTaskWithNotification(Long taskId) {
        TaskResponse response = taskService.completeTask(taskId);

        notificationService.notifyCompletion(taskId);
        auditService.logAction("COMPLETE", taskId);

        return response;
    }
}

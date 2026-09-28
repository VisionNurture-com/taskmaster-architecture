package com.example.taskmaster.application;

import com.example.taskmaster.domain.Task;
import com.example.taskmaster.domain.TaskStatus;
import java.time.LocalDate;

public record TaskResponse(
        Long id,
        String title,
        String description,
        LocalDate dueDate,
        TaskStatus status
) {
    public static TaskResponse from(Task task) {
        return new TaskResponse(
                task.getId(),
                task.getTitle(),
                task.getDescription(),
                task.getDueDate(),
                task.getStatus()
        );
    }
}

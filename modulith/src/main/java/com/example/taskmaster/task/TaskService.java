package com.example.taskmaster.task;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TaskService {

    private final TaskRepository repository;
    private final ApplicationEventPublisher events;

    public TaskService(TaskRepository repository,
                       ApplicationEventPublisher events) {
        this.repository = repository;
        this.events = events;
    }

    @Transactional
    public void completeTask(Long taskId) {
        Task task = repository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException(taskId));
        task.complete();
        repository.save(task);
        events.publishEvent(new TaskCompletedEvent(taskId, task.getTitle()));
    }
}

package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.Task;
import com.example.taskmaster.domain.TaskStatus;
import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "tasks")
public class TaskJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 1000)
    private String description;

    @Column(name = "due_date")
    private LocalDate dueDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TaskStatus status;

    protected TaskJpaEntity() {}

    static TaskJpaEntity fromDomain(Task task) {
        TaskJpaEntity entity = new TaskJpaEntity();
        entity.id = task.getId();
        entity.title = task.getTitle();
        entity.description = task.getDescription();
        entity.dueDate = task.getDueDate();
        entity.status = task.getStatus();
        return entity;
    }

    Task toDomain() {
        return new Task(id, title, description, dueDate, status);
    }
}

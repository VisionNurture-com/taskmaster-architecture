package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.Task;
import com.example.taskmaster.domain.TaskStatus;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

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

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(name = "task_tags",
            joinColumns = @JoinColumn(name = "task_id"),
            inverseJoinColumns = @JoinColumn(name = "tag_id"))
    private Set<TagJpaEntity> tags = new HashSet<>();

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

    Set<TagJpaEntity> getTags() {
        return tags;
    }
}

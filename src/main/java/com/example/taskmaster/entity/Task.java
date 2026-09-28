package com.example.taskmaster.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "tasks")
public class Task {

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

    protected Task() {}

    /** 新規タスク作成用コンストラクタ */
    public Task(String title, String description, LocalDate dueDate) {
        this.title = title;
        this.description = description;
        this.dueDate = dueDate;
        this.status = TaskStatus.TODO;
        validate();
    }

    /** DB復元用コンストラクタ */
    public Task(Long id, String title, String description,
                LocalDate dueDate, TaskStatus status) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.dueDate = dueDate;
        this.status = status;
    }

    public void complete() {
        if (this.status == TaskStatus.DONE) {
            throw new IllegalStateException(
                    "Task is already completed.");
        }
        this.status = TaskStatus.DONE;
    }

    public void startProgress() {
        if (this.status != TaskStatus.TODO) {
            throw new IllegalStateException(
                    "Only TODO tasks can be started. Current: " + this.status);
        }
        this.status = TaskStatus.IN_PROGRESS;
    }

    public boolean isOverdue() {
        return this.dueDate != null
                && this.status != TaskStatus.DONE
                && LocalDate.now().isAfter(this.dueDate);
    }

    private void validate() {
        if (title == null || title.isBlank()) {
            throw new IllegalArgumentException("Title must not be blank.");
        }
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public LocalDate getDueDate() { return dueDate; }
    public TaskStatus getStatus() { return status; }
}

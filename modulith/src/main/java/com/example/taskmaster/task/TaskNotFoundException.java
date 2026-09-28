package com.example.taskmaster.task;

// 記事にないクラス（補い）
public class TaskNotFoundException extends RuntimeException {

    public TaskNotFoundException(Long id) {
        super("Task not found: id=" + id);
    }
}

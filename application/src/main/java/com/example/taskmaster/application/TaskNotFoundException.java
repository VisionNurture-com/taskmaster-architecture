package com.example.taskmaster.application;

public class TaskNotFoundException extends RuntimeException {

    public TaskNotFoundException(Long id) {
        super("Task not found: id=" + id);
    }
}

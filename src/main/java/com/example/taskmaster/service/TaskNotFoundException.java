package com.example.taskmaster.service;

public class TaskNotFoundException extends RuntimeException {
    public TaskNotFoundException(Long id) {
        super("タスクが見つかりません（ID: " + id + "）");
    }
}

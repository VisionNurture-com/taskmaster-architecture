package com.example.taskmaster.task;

public record TaskCompletedEvent(Long taskId, String title) {}

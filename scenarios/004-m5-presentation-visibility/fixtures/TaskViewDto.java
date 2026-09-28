package com.example.taskmaster.presentation;

import com.example.taskmaster.application.TaskResponse;

public class TaskView {
    public String label(TaskResponse response) {
        return response.title() + " (" + response.status() + ")";
    }
}

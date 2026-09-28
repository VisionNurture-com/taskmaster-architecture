package com.example.taskmaster.presentation;

import com.example.taskmaster.domain.Task;

public class TaskView {
    public String title(Task task) {
        return task.getTitle();
    }
}

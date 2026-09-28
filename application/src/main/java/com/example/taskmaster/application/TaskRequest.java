package com.example.taskmaster.application;

import java.time.LocalDate;

public record TaskRequest(
        String title,
        String description,
        LocalDate dueDate
) {}

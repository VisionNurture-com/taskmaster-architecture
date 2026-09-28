package com.example.taskmaster.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record TaskRequest(
    @NotBlank(message = "タイトルは必須です")
    @Size(max = 200, message = "タイトルは200文字以内で入力してください")
    String title,

    @Size(max = 1000, message = "説明は1000文字以内で入力してください")
    String description,

    LocalDate dueDate
) {}

package com.example.taskmaster.task;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

// 記事にないクラス（補い）。completeTask() が使う complete() と getTitle() だけを持つ
@Entity
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    private boolean done;

    protected Task() {}

    public Task(String title) {
        this.title = title;
    }

    public void complete() {
        this.done = true;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public boolean isDone() { return done; }
}

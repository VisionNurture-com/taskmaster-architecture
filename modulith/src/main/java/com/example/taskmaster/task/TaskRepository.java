package com.example.taskmaster.task;

import org.springframework.data.jpa.repository.JpaRepository;

// 記事にないクラス（補い）
public interface TaskRepository extends JpaRepository<Task, Long> {
}

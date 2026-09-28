package com.example.taskmaster.domain;

import java.util.List;
import java.util.Optional;

public interface TaskRepository {

    Task save(Task task);

    Optional<Task> findById(Long id);

    List<Task> findAll();

    void deleteById(Long id);

    boolean existsById(Long id);

    /** 006: 状態で絞り、期限の早い順に page 番目（0 始まり）の size 件を返す */
    List<Task> findByStatus(TaskStatus status, int page, int size);
}

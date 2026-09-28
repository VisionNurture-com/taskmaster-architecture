package com.example.taskmaster.application;

import com.example.taskmaster.domain.Task;
import com.example.taskmaster.domain.TaskRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class TaskService {

    private final TaskRepository taskRepository;

    public TaskService(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    @Transactional(readOnly = true)
    public List<TaskResponse> findAll() {
        return taskRepository.findAll().stream()
                .map(TaskResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public TaskResponse findById(Long id) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new TaskNotFoundException(id));
        return TaskResponse.from(task);
    }

    @Transactional
    public TaskResponse create(TaskRequest request) {
        Task task = new Task(
                request.title(),
                request.description(),
                request.dueDate());
        Task saved = taskRepository.save(task);
        return TaskResponse.from(saved);
    }

    @Transactional
    public TaskResponse update(Long id, TaskRequest request) {
        Task existing = taskRepository.findById(id)
                .orElseThrow(() -> new TaskNotFoundException(id));
        Task task = new Task(
                id,
                request.title(),
                request.description(),
                request.dueDate(),
                existing.getStatus());
        Task saved = taskRepository.save(task);
        return TaskResponse.from(saved);
    }

    @Transactional
    public TaskResponse completeTask(Long taskId) {
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException(taskId));
        task.complete();  // Taskが状態遷移ルールを管理
        return TaskResponse.from(taskRepository.save(task));
    }

    @Transactional
    public TaskResponse startTask(Long taskId) {
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException(taskId));
        task.startProgress();  // Taskが状態遷移ルールを管理
        return TaskResponse.from(taskRepository.save(task));
    }

    @Transactional
    public void delete(Long id) {
        if (!taskRepository.existsById(id)) {
            throw new TaskNotFoundException(id);
        }
        taskRepository.deleteById(id);
    }
}

package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.Task;
import com.example.taskmaster.domain.TaskRepository;
import com.example.taskmaster.domain.TaskStatus;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class JpaTaskRepository implements TaskRepository {

    private final SpringDataTaskRepository springDataRepository;

    public JpaTaskRepository(SpringDataTaskRepository springDataRepository) {
        this.springDataRepository = springDataRepository;
    }

    @Override
    public Task save(Task task) {
        return springDataRepository.save(TaskJpaEntity.fromDomain(task)).toDomain();
    }

    @Override
    public Optional<Task> findById(Long id) {
        return springDataRepository.findById(id).map(TaskJpaEntity::toDomain);
    }

    @Override
    public List<Task> findAll() {
        return springDataRepository.findAll().stream()
                .map(TaskJpaEntity::toDomain)
                .toList();
    }

    @Override
    public void deleteById(Long id) {
        springDataRepository.deleteById(id);
    }

    @Override
    public boolean existsById(Long id) {
        return springDataRepository.existsById(id);
    }

    @Override
    public List<Task> findByStatus(TaskStatus status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size,
                Sort.by("dueDate").ascending());
        return springDataRepository.findByStatus(status, pageable)
                .map(TaskJpaEntity::toDomain)
                .getContent();
    }
}

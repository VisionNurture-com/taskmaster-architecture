package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.Task;
import com.example.taskmaster.domain.TaskRepository;
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
}

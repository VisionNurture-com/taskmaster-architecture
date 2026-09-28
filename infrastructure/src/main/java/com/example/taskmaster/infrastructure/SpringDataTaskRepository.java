package com.example.taskmaster.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

interface SpringDataTaskRepository extends JpaRepository<TaskJpaEntity, Long> {
}

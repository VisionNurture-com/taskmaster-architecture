package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.TaskStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

interface SpringDataTaskRepository
        extends JpaRepository<TaskJpaEntity, Long>,
                JpaSpecificationExecutor<TaskJpaEntity> {

    @Query("SELECT DISTINCT t FROM TaskJpaEntity t "
         + "LEFT JOIN FETCH t.tags")
    List<TaskJpaEntity> findAllWithTags();

    @Query("SELECT t FROM TaskJpaEntity t "
         + "WHERE t.status = :status "
         + "ORDER BY t.dueDate ASC")
    List<TaskJpaEntity> findByStatus(
            @Param("status") TaskStatus status);

    @Query("SELECT t FROM TaskJpaEntity t "
         + "WHERE t.dueDate < CURRENT_DATE "
         + "AND t.status <> 'DONE'")
    List<TaskJpaEntity> findOverdueTasks();

    Page<TaskJpaEntity> findByStatus(
            TaskStatus status, Pageable pageable);
}

package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.TaskStatus;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDate;

public class TaskSpecifications {

    public static Specification<TaskJpaEntity> hasStatus(TaskStatus status) {
        return (root, query, cb) ->
                cb.equal(root.get("status"), status);
    }

    public static Specification<TaskJpaEntity> isOverdue() {
        return (root, query, cb) ->
                cb.and(
                        cb.lessThan(root.get("dueDate"), LocalDate.now()),
                        cb.notEqual(root.get("status"), TaskStatus.DONE));
    }
}

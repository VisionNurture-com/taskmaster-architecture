package com.example.taskmaster.infrastructure;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

// 測定用（記事には載せない）。記事の @EntityGraph の書き方（findAll の上書き）と、fetch join ＋ Pageable を試す
interface GraphTaskRepository extends JpaRepository<TaskJpaEntity, Long> {

    @EntityGraph(attributePaths = {"tags"})
    @Override
    List<TaskJpaEntity> findAll();

    @Query("SELECT t FROM TaskJpaEntity t LEFT JOIN FETCH t.tags")
    List<TaskJpaEntity> findAllWithTagsNoDistinct();

    @Query("SELECT t FROM TaskJpaEntity t LEFT JOIN FETCH t.tags")
    List<TaskJpaEntity> findAllWithTagsPaged(Pageable pageable);
}

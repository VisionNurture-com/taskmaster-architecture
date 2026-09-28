package com.example.taskmaster.infrastructure;

import jakarta.persistence.*;

/** 006: タスクに付けるタグ（JPA のためだけのクラス） */
@Entity
@Table(name = "tags")
public class TagJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String name;

    protected TagJpaEntity() {}

    public TagJpaEntity(String name) {
        this.name = name;
    }

    public Long getId() { return id; }
    public String getName() { return name; }
}

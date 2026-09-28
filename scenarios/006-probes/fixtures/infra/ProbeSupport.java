package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.Task;
import jakarta.persistence.EntityManagerFactory;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.springframework.orm.jpa.EntityManagerFactoryUtils;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDate;

// 測定用（記事には載せない）
final class ProbeSupport {

    private ProbeSupport() {}

    static Statistics stats(EntityManagerFactory emf) {
        return emf.unwrap(SessionFactory.class).getStatistics();
    }

    /** n 件のタスクに、それぞれタグを 2 件付けて保存する */
    static void seed(TransactionTemplate tx, EntityManagerFactory emf, int n) {
        tx.executeWithoutResult(s -> {
            jakarta.persistence.EntityManager em = EntityManagerFactoryUtils.getTransactionalEntityManager(emf);
            for (int i = 0; i < n; i++) {
                TaskJpaEntity t = TaskJpaEntity.fromDomain(new Task("task-" + i, null, LocalDate.of(2026, 1, 1).plusDays(i)));
                TagJpaEntity a = new TagJpaEntity("a-" + i);
                TagJpaEntity b = new TagJpaEntity("b-" + i);
                em.persist(a);
                em.persist(b);
                t.getTags().add(a);
                t.getTags().add(b);
                em.persist(t);
            }
        });
    }

    /** TaskJpaEntity の id を読む（本体に getter を足さないため、toDomain を経由する）*/
    static Long id(TaskJpaEntity t) {
        return t.toDomain().getId();
    }

    static void print(String key, Object value) {
        System.out.println("PROBE " + key + "=" + value);
    }
}

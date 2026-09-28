package com.example.taskmaster.infrastructure;

import com.example.taskmaster.domain.Task;
import com.example.taskmaster.domain.TaskStatus;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import org.hibernate.FlushMode;
import org.hibernate.Session;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.data.domain.PageRequest;
import org.springframework.orm.jpa.EntityManagerFactoryUtils;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import java.util.List;

// 測定用（記事には載せない）。R1〜R3・R5・R9・R14・Specification の使用例
@SpringBootTest(classes = InfraTestApplication.class, properties = {
        "spring.jpa.hibernate.ddl-auto=create",
        "spring.jpa.properties.hibernate.generate_statistics=true",
        "spring.jpa.show-sql=true"})
@Testcontainers
@ExtendWith(OutputCaptureExtension.class)
class QueryCountProbeTest {

    static final int N = Integer.getInteger("probe.n", 10);

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:17-alpine");

    @Autowired SpringDataTaskRepository repo;
    @Autowired GraphTaskRepository graphRepo;
    @Autowired JpaTaskRepository adapter;
    @Autowired EntityManagerFactory emf;
    @Autowired PlatformTransactionManager tm;

    TransactionTemplate tx;

    @BeforeEach
    void setUp() {
        tx = new TransactionTemplate(tm);
        if (repo.count() == 0) {
            ProbeSupport.seed(tx, emf, N);
        }
    }

    private long countStatements(Runnable r) {
        Statistics s = ProbeSupport.stats(emf);
        s.clear();
        tx.executeWithoutResult(st -> r.run());
        return s.getPrepareStatementCount();
    }

    @Test
    void r1_r2_r3_r5_r9_r14(CapturedOutput output) {
        ProbeSupport.print("N", N);
        ProbeSupport.print("R1_plainFindAllThenTouchTags", countStatements(() -> repo.findAll().forEach(t -> t.getTags().size())));
        long[] size = new long[1];
        ProbeSupport.print("R2_fetchJoinDistinct", countStatements(() -> { List<TaskJpaEntity> l = repo.findAllWithTags(); size[0] = l.size(); l.forEach(t -> t.getTags().size()); }));
        ProbeSupport.print("R2_fetchJoinDistinct_rows", size[0]);
        ProbeSupport.print("R2b_fetchJoinNoDistinct", countStatements(() -> { List<TaskJpaEntity> l = graphRepo.findAllWithTagsNoDistinct(); size[0] = l.size(); }));
        ProbeSupport.print("R2b_fetchJoinNoDistinct_rows", size[0]);
        ProbeSupport.print("R3_entityGraphFindAll", countStatements(() -> graphRepo.findAll().forEach(t -> t.getTags().size())));

        TransactionTemplate ro = new TransactionTemplate(tm);
        ro.setReadOnly(true);
        ro.executeWithoutResult(st -> {
            EntityManager em = EntityManagerFactoryUtils.getTransactionalEntityManager(emf);
            FlushMode mode = em.unwrap(Session.class).getHibernateFlushMode();
            ProbeSupport.print("R5_readOnlyFlushMode", mode);
        });
        tx.executeWithoutResult(st -> {
            EntityManager em = EntityManagerFactoryUtils.getTransactionalEntityManager(emf);
            ProbeSupport.print("R5_readWriteFlushMode", em.unwrap(Session.class).getHibernateFlushMode());
        });

        long warnBefore = output.getAll().lines().filter(l -> l.contains("HHH90003004:")).count();
        long pagedRows = tx.execute(st -> (long) graphRepo.findAllWithTagsPaged(PageRequest.of(0, 3)).size());
        ProbeSupport.print("R9_HHH90003004_warnLines", output.getAll().lines().filter(l -> l.contains("HHH90003004:")).count() - warnBefore);
        ProbeSupport.print("R9b_pagedRows", pagedRows);
        long warnBeforeC = output.getAll().lines().filter(l -> l.contains("HHH90003004:")).count();
        long directRows = tx.execute(st -> (long) EntityManagerFactoryUtils.getTransactionalEntityManager(emf)
                .createQuery("SELECT t FROM TaskJpaEntity t LEFT JOIN FETCH t.tags", TaskJpaEntity.class)
                .setFirstResult(0).setMaxResults(3).getResultList().size());
        ProbeSupport.print("R9c_entityManagerRows", directRows);
        ProbeSupport.print("R9c_HHH90003004_warnLines", output.getAll().lines().filter(l -> l.contains("HHH90003004:")).count() - warnBeforeC);

        long overdue = tx.execute(st -> (long) repo.findAll(TaskSpecifications.hasStatus(TaskStatus.TODO).and(TaskSpecifications.isOverdue())).size());
        ProbeSupport.print("SPEC_todoAndOverdue", overdue);

        Long id = tx.execute(st -> ProbeSupport.id(repo.findAll().get(0)));
        long before = tx.execute(st -> (long) repo.findById(id).orElseThrow().getTags().size());
        tx.executeWithoutResult(st -> {
            Task task = adapter.findById(id).orElseThrow();
            task.complete();
            adapter.save(task);
        });
        long after = tx.execute(st -> (long) repo.findById(id).orElseThrow().getTags().size());
        ProbeSupport.print("R14_tagsBeforeComplete", before);
        ProbeSupport.print("R14_tagsAfterComplete", after);
    }
}

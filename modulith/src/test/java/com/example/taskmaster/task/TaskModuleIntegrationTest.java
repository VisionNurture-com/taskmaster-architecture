package com.example.taskmaster.task;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.modulith.test.ApplicationModuleTest;
import org.springframework.modulith.test.Scenario;

import static org.assertj.core.api.Assertions.assertThat;

@ApplicationModuleTest
class TaskModuleIntegrationTest {

    @Autowired
    private TaskService taskService;

    @Autowired
    private TaskRepository repository;

    @Test
    void completingTaskPublishesEvent(Scenario scenario) {
        Long taskId = repository.save(new Task("週報を書く")).getId();

        scenario.stimulate(() -> taskService.completeTask(taskId))
                .andWaitForEventOfType(TaskCompletedEvent.class)
                .toArriveAndVerify(event ->
                        assertThat(event.taskId()).isEqualTo(taskId));
    }
}

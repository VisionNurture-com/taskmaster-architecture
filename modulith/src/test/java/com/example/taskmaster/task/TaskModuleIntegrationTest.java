package com.example.taskmaster.task;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.modulith.test.ApplicationModuleTest;
import org.springframework.modulith.test.Scenario;

@ApplicationModuleTest
class TaskModuleIntegrationTest {

    @Autowired
    private TaskService taskService;

    @Test
    void completingTaskPublishesEvent(Scenario scenario) {
        scenario.stimulate(() -> taskService.completeTask(1L))
                .andWaitForEventOfType(TaskCompletedEvent.class)
                .toArriveAndVerify(event ->
                        assertThat(event.taskId()).isEqualTo(1L));
    }
}

package com.example.taskmaster;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

class ModularityTests {

    @Test
    void verifyModularStructure() {
        ApplicationModules modules = ApplicationModules.of(TaskmasterApplication.class);
        modules.detectViolations()
                .filter(v -> !v.getMessage().contains("TaskValidator"))
                .throwIfPresent();
    }
}

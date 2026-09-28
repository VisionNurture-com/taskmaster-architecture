package com.example.taskmaster.application;

import com.example.taskmaster.domain.Task;
import com.example.taskmaster.domain.TaskRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class TaskServiceTest {

    @Mock
    TaskRepository taskRepository;

    @InjectMocks
    TaskService taskService;

    @Test
    @DisplayName("タスクを作成できる")
    void createTask() {
        var request = new TaskRequest("テスト", "テスト説明", null);
        var task = new Task("テスト", "テスト説明", null);
        given(taskRepository.save(any(Task.class))).willReturn(task);

        TaskResponse response = taskService.create(request);

        assertThat(response.title()).isEqualTo("テスト");
    }

    @Test
    @DisplayName("存在しないIDでTaskNotFoundExceptionがスローされる")
    void findByIdNotFound() {
        given(taskRepository.findById(999L)).willReturn(java.util.Optional.empty());

        assertThatThrownBy(() -> taskService.findById(999L))
                .isInstanceOf(TaskNotFoundException.class)
                .hasMessageContaining("999");
    }
}

package com.example.taskmaster.service;

import com.example.taskmaster.dto.TaskRequest;
import com.example.taskmaster.dto.TaskResponse;
import com.example.taskmaster.entity.Task;
import com.example.taskmaster.repository.TaskRepository;
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
        var request = new TaskRequest("テスト", "テスト説明");
        var task = new Task("テスト", "テスト説明");
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

package com.example.taskmaster.application;

import com.example.taskmaster.domain.Task;
import com.example.taskmaster.domain.TaskRepository;
import com.example.taskmaster.domain.TaskStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// 対照: TaskServiceTest と同じ 3 件を、Spring のコンテキストを起動して行う
@SpringJUnitConfig(TaskServiceSpringContextTest.Config.class)
class TaskServiceSpringContextTest {

    @Configuration
    static class Config {
        @Bean
        TaskRepository taskRepository() {
            return Mockito.mock(TaskRepository.class);
        }

        @Bean
        TaskService taskService(TaskRepository taskRepository) {
            return new TaskService(taskRepository);
        }
    }

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private TaskService taskService;

    @BeforeEach
    void resetMock() {
        Mockito.reset(taskRepository);
    }

    @Test
    @DisplayName("タスク作成でリポジトリのsaveが呼ばれる")
    void createCallsRepositorySave() {
        TaskRequest request = new TaskRequest(
                "新しいタスク", "説明文",
                LocalDate.of(2026, 5, 1));
        Task savedTask = new Task(1L, "新しいタスク", "説明文",
                LocalDate.of(2026, 5, 1), TaskStatus.TODO);

        when(taskRepository.save(any(Task.class)))
                .thenReturn(savedTask);

        TaskResponse response = taskService.create(request);

        assertThat(response.id()).isEqualTo(1L);
        assertThat(response.title()).isEqualTo("新しいタスク");
        assertThat(response.status()).isEqualTo(TaskStatus.TODO);
        verify(taskRepository).save(any(Task.class));
    }

    @Test
    @DisplayName("存在しないIDで検索すると例外")
    void findByIdNotFoundThrowsException() {
        when(taskRepository.findById(99L))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.findById(99L))
                .isInstanceOf(TaskNotFoundException.class)
                .hasMessageContaining("99");
    }

    @Test
    @DisplayName("全タスク取得でDTOリストを返す")
    void findAllReturnsDtoList() {
        List<Task> tasks = List.of(
                new Task(1L, "タスク1", "説明1",
                        LocalDate.of(2026, 5, 1), TaskStatus.TODO),
                new Task(2L, "タスク2", "説明2",
                        LocalDate.of(2026, 5, 2), TaskStatus.DONE)
        );
        when(taskRepository.findAll()).thenReturn(tasks);

        List<TaskResponse> responses = taskService.findAll();

        assertThat(responses).hasSize(2);
        assertThat(responses.get(0).title()).isEqualTo("タスク1");
        assertThat(responses.get(1).status()).isEqualTo(TaskStatus.DONE);
    }
}

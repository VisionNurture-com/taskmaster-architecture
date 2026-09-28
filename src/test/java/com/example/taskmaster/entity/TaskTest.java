package com.example.taskmaster.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class TaskTest {

    @Nested
    @DisplayName("タスク作成")
    class Creation {

        @Test
        @DisplayName("新規タスクのステータスはTODO")
        void newTaskHasTodoStatus() {
            Task task = new Task("テスト", "説明",
                    LocalDate.now().plusDays(7));

            assertThat(task.getStatus()).isEqualTo(TaskStatus.TODO);
            assertThat(task.getId()).isNull();
        }

        @Test
        @DisplayName("タイトルが空の場合は例外")
        void blankTitleThrowsException() {
            assertThatThrownBy(() ->
                    new Task("", "説明", LocalDate.now()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Title");
        }
    }

    @Nested
    @DisplayName("状態遷移")
    class StatusTransition {

        @Test
        @DisplayName("TODOタスクを開始するとIN_PROGRESS")
        void startProgressChangesStatus() {
            Task task = new Task("テスト", "説明",
                    LocalDate.now().plusDays(7));

            task.startProgress();

            assertThat(task.getStatus())
                    .isEqualTo(TaskStatus.IN_PROGRESS);
        }

        @Test
        @DisplayName("タスクを完了するとDONE")
        void completeChangesStatus() {
            Task task = new Task("テスト", "説明",
                    LocalDate.now().plusDays(7));

            task.complete();

            assertThat(task.getStatus())
                    .isEqualTo(TaskStatus.DONE);
        }

        @Test
        @DisplayName("完了済みタスクの再完了は例外")
        void completeAlreadyDoneThrowsException() {
            Task task = new Task("テスト", "説明",
                    LocalDate.now().plusDays(7));
            task.complete();

            assertThatThrownBy(task::complete)
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("already completed");
        }

        @Test
        @DisplayName("IN_PROGRESSタスクの開始は例外")
        void startAlreadyInProgressThrowsException() {
            Task task = new Task("テスト", "説明",
                    LocalDate.now().plusDays(7));
            task.startProgress();

            assertThatThrownBy(task::startProgress)
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("Only TODO");
        }
    }

    @Nested
    @DisplayName("期限超過判定")
    class OverdueCheck {

        @Test
        @DisplayName("期限を過ぎた未完了タスクはoverdue")
        void pastDueDateIsOverdue() {
            Task task = new Task("テスト", "説明",
                    LocalDate.now().minusDays(1));

            assertThat(task.isOverdue()).isTrue();
        }

        @Test
        @DisplayName("完了済みタスクはoverdueにならない")
        void completedTaskIsNotOverdue() {
            Task task = new Task("テスト", "説明",
                    LocalDate.now().minusDays(1));
            task.complete();

            assertThat(task.isOverdue()).isFalse();
        }

        @Test
        @DisplayName("期限が未来のタスクはoverdueでない")
        void futureDueDateIsNotOverdue() {
            Task task = new Task("テスト", "説明",
                    LocalDate.now().plusDays(7));

            assertThat(task.isOverdue()).isFalse();
        }
    }
}

// notification モジュール: イベントリスナー
package com.example.taskmaster.notification;

import com.example.taskmaster.task.TaskCompletedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class NotificationListener {

    @EventListener
    public void onTaskCompleted(TaskCompletedEvent event) {
        System.out.println("通知送信: タスク「" + event.title() + "」が完了しました");
    }
}

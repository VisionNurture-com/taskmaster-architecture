package com.example.taskmaster.report;

import com.example.taskmaster.task.TaskCompletedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

// 記事にないクラス（補い）。記事の図 3 どおり TaskCompletedEvent を受け取る
@Service
public class ReportService {

    @EventListener
    public void onTaskCompleted(TaskCompletedEvent event) {
        System.out.println("集計: タスク " + event.taskId() + " を完了に数えました");
    }
}

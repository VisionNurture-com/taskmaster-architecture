package com.example.taskmaster.application;

import org.springframework.stereotype.Service;

/** 006: タスクの完了を知らせる（サンプルでは標準出力に書くだけ） */
@Service
public class NotificationService {

    public void notifyCompletion(Long taskId) {
        System.out.println("通知: タスク " + taskId + " が完了しました");
    }
}

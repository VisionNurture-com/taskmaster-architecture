package com.example.taskmaster.task.internal;

// 測定用（記事の ⚠️ 注意の例に合わせた名前）。task モジュールの内部に置く
public class TaskValidator {

    public boolean isValid(String title) {
        return title != null && !title.isBlank();
    }
}

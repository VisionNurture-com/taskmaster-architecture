package com.example.taskmaster.infrastructure;

import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronizationManager;

// 測定用（記事には載せない）。R11: public ではないメソッドに @Transactional が効くか
@Component
class TxVisibilityProbe {

    @Transactional
    public boolean publicMethod() {
        return TransactionSynchronizationManager.isActualTransactionActive();
    }

    @Transactional
    boolean packagePrivateMethod() {
        return TransactionSynchronizationManager.isActualTransactionActive();
    }

    @Transactional
    protected boolean protectedMethod() {
        return TransactionSynchronizationManager.isActualTransactionActive();
    }
}

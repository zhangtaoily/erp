package com.eerp.common.tx;

import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * 事务边界工具
 */
@Component
public class TransactionBoundary {

    private final PlatformTransactionManager transactionManager;

    public TransactionBoundary(PlatformTransactionManager transactionManager) {
        this.transactionManager = transactionManager;
    }

    /**
     * 在事务中执行（存在则加入，不存在则新建）
     */
    public void executeInTx(Runnable action) {
        TransactionTemplate template = new TransactionTemplate(transactionManager);
        template.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRED);
        template.executeWithoutResult(status -> action.run());
    }

    /**
     * 在无事务环境中执行（挂起当前事务）
     */
    public void executeWithoutTx(Runnable action) {
        TransactionTemplate template = new TransactionTemplate(transactionManager);
        template.setPropagationBehavior(TransactionDefinition.PROPAGATION_NOT_SUPPORTED);
        template.executeWithoutResult(status -> action.run());
    }

    /**
     * 在新事务中执行（始终开启新事务，挂起当前事务）
     */
    public void executeNewTx(Runnable action) {
        TransactionTemplate template = new TransactionTemplate(transactionManager);
        template.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        template.executeWithoutResult(status -> action.run());
    }
}

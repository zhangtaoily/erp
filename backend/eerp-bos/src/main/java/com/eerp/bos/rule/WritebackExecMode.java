package com.eerp.bos.rule;

/**
 * 反写执行模式枚举（对齐设计文档 08 §3.7 / §5.6）。
 *
 * <ul>
 *   <li>SYNC（同步，事务内）：在主事务内执行，失败回滚主事务（数据完整性要求高的反写）</li>
 *   <li>ASYNC（异步，事务后）：在主事务 afterCommit 回调中异步执行，
 *       失败记录到 biz_writeback_log 由补偿服务重试</li>
 * </ul>
 */
public enum WritebackExecMode {

    /** 同步：事务内执行，失败抛异常回滚 */
    SYNC("sync"),
    /** 异步：事务后执行，失败记录 biz_writeback_log 补偿 */
    ASYNC("async");

    private final String code;

    WritebackExecMode(String code) {
        this.code = code;
    }

    public String getCode() {
        return code;
    }

    /**
     * 按 code 解析枚举（大小写不敏感）。
     *
     * @param code 模式编码（sync/async）
     * @return 枚举值；未匹配或 null 返回 SYNC（默认同步）
     */
    public static WritebackExecMode fromCode(String code) {
        if (code == null) {
            return SYNC;
        }
        String lower = code.toLowerCase();
        for (WritebackExecMode mode : values()) {
            if (mode.code.equals(lower)) {
                return mode;
            }
        }
        return SYNC;
    }
}

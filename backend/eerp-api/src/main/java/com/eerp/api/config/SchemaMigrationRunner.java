package com.eerp.api.config;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * 启动时自动检查并补充数据库表结构（仅对缺失列执行 ALTER TABLE）。
 * 避免 H2/MySQL 环境因表结构不一致导致运行时 SQL 语法错误。
 */
@Component
public class SchemaMigrationRunner implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    public SchemaMigrationRunner(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(ApplicationArguments args) {
        addColumnIfMissing("meta_query_field", "entity_code", "varchar(50) DEFAULT NULL");
        addColumnIfMissing("meta_form_field", "is_readonly", "SMALLINT DEFAULT 0");
        // 联动赋值：上级表字段变更时，下级表对应字段批量赋同值（如主表仓库 → 子表仓库）
        addColumnIfMissing("meta_form_field", "link_from", "varchar(100) DEFAULT NULL");
        // 金额字段设置计算公式 qty*price，取消 is_system 标记使其可自动计算
        try {
            jdbcTemplate.update("UPDATE meta_form_field SET formula = 'qty*price', is_system = 0 " +
                    "WHERE bo_code = 'SAL_INT_CONT' AND entity_code = 'goods' AND field_code = 'amount' " +
                    "AND (formula IS NULL OR formula = '' OR is_system = 1)");
        } catch (Exception e) {
            System.err.println("[SchemaMigration] 更新金额字段公式失败: " + e.getMessage());
        }
    }

    /**
     * 检查表是否有指定列，没有则添加。
     *
     * @param table    表名
     * @param column   列名
     * @param typeDef  列类型定义（如 "varchar(50) DEFAULT NULL"）
     */
    private void addColumnIfMissing(String table, String column, String typeDef) {
        try {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM information_schema.COLUMNS "
                            + "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?",
                    Integer.class, table, column);
            if (count != null && count == 0) {
                jdbcTemplate.execute("ALTER TABLE `" + table + "` ADD COLUMN `" + column + "` " + typeDef);
                System.out.println("[SchemaMigration] 已添加列: " + table + "." + column);
            }
        } catch (Exception e) {
            System.err.println("[SchemaMigration] 检查/添加列失败: " + table + "." + column + " — " + e.getMessage());
        }
    }
}

-- ERP 数据库初始化脚本
-- 使用方法：在 MySQL 中执行此脚本（需先创建 eerp 数据库）
-- 或通过 docker-compose up 自动执行

CREATE DATABASE IF NOT EXISTS eerp DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE eerp;

-- 1. 平台元数据表
SOURCE database/schema/00-平台元数据表.sql;
-- 2. 基础资料表
SOURCE database/schema/01-基础资料表.sql;
-- 3. 系统管理表
SOURCE database/schema/10-系统管理表.sql;
-- 4. 消息预警表
SOURCE database/schema/10-消息预警表.sql;
-- 5. 种子数据-系统管理
SOURCE database/seed/V1.0.0__seed_admin.sql;
-- 6. 种子数据-元数据
SOURCE database/seed/V1.0.1__seed_meta.sql;
-- 7. 种子数据-字典
SOURCE database/seed/V1.0.2__seed_dict.sql;

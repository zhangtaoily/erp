-- ============================================================
-- EERP H2 Master Data Extension Schema
-- ============================================================
-- 用途：主数据元数据种子（data-h2-master-seed.sql）所需的扩展表 DDL。
--       当 SYS_DICT 业务对象以 id 为主键、sys_dict_item 以 dict_id 关联时，
--       需要本文件提供对应表结构。使用 CREATE TABLE IF NOT EXISTS 保证幂等。
-- 加载：在 schema-h2.sql 之后加载（schema-locations 追加本文件）。
-- 兼容：H2 MODE=MySQL；时间戳使用 timestamp；主键 bigint（雪花ID，非自增）。
-- ============================================================

-- sys_dict：数据字典（主数据，id 主键结构）
-- 注意：schema-h2.sql 中已有不同结构的 sys_dict 表（PK=dict_code），
-- 需先 DROP 再 CREATE 以匹配 SysDict 实体（extends BaseEntity，PK=id）
DROP TABLE IF EXISTS sys_dict_item;
DROP TABLE IF EXISTS sys_dict;
CREATE TABLE sys_dict (
  id bigint NOT NULL,
  dict_code varchar(100),
  dict_name varchar(200),
  remark varchar(500),
  status int DEFAULT 1,
  create_by varchar(200),
  create_time timestamp,
  update_by varchar(200),
  update_time timestamp,
  PRIMARY KEY (id)
);

-- sys_dict_item：字典枚举项（通过 dict_id 关联 sys_dict.id）
CREATE TABLE sys_dict_item (
  id bigint NOT NULL,
  dict_id bigint,
  item_code varchar(100),
  item_name varchar(200),
  sort_index int DEFAULT 0,
  enabled int DEFAULT 1,
  remark varchar(500),
  PRIMARY KEY (id)
);

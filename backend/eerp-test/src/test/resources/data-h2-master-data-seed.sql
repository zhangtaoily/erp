-- ============================================================
-- EERP H2 Master Data Instance Seed
-- ============================================================
-- 用途：集成测试 H2 内存数据库主数据实例种子。
--       为 30 个主数据业务对象（含 5 个子表）造完整的测试数据，
--       使前端"引用"字段下拉选项不为空，单据可正确填写
--       sal_org_id / cust_id / dept_id / saler_id / curr_id /
--       mat_id / unit_id 等字段。
-- 加载：在 data-h2-master-seed.sql 之后、业务模块种子
--       （data-h2-sal-seed.sql 等）之前加载。
-- 幂等：全部使用 REPLACE INTO，可重复执行。
-- ID 区间：3000001 - 3000999
--   （避开元数据种子 100001-100030 / 150001-150035 / 200001-200200
--     和 data-h2-seed.sql 中已有的 1-3）
-- 兼容：H2 MODE=MySQL + MySQL 8.4
--   - 时间戳用 CURRENT_TIMESTAMP
--   - 布尔值用 1/0（不用 true/false）
--   - 不用 INSERT ... ON DUPLICATE KEY UPDATE
-- 依赖关系：
--   sys_org → sys_dept → sys_employee → sys_saler / sys_merchandiser
--   md_currency → md_exchange_rate / md_customer / md_supplier
--   md_material_group → md_material
--   md_raw_material_group → md_raw_material → md_raw_material_detail
--   md_color_series → md_comp_color → md_print_color / md_hl_card
--   md_warehouse → md_position
--   md_unit / md_brand / md_trade_type / md_harbour / md_quality_std /
--   md_firp_type / md_spin_fee / sys_dict（无外键依赖）
--   md_spin_fee → md_spin_fee_material / md_spin_fee_raw_material
--   md_credit → md_credit_detail
--   sys_dict → sys_dict_item
-- ============================================================


-- ============================================================
-- 0. 清理旧的最小化种子数据（data-h2-seed.sql 中 id=1,2,3 的行）
--    原因：H2 的 REPLACE INTO 实现为 MERGE，不会按 UNIQUE(code)
--    删除冲突行；以下表存在 code 冲突（CNY/USD/KG/M/PCS/SALES_DEPT/
--    EMP001/EMP002），需先删除旧行再插入完整数据。
--    注：sys_org/md_customer/md_supplier/md_material/md_warehouse 的
--    旧 code 与新数据不冲突，保留旧行。
-- ============================================================
DELETE FROM sys_dept      WHERE id IN (1, 2);
DELETE FROM sys_employee  WHERE id IN (1, 2);
DELETE FROM md_currency   WHERE id IN (1, 2);
DELETE FROM md_unit       WHERE id IN (1, 2, 3);


-- ============================================================
-- 1. 组织（sys_org）—— 5 行
-- ============================================================
REPLACE INTO sys_org (id, code, name, org_type, parent_id, is_accounting, is_business, base_curr_id, tax_no, address, status, sort_index, create_by, create_time, update_by, update_time) VALUES
  (3000001, 'HEAD_OFFICE',  '总公司',       'GROUP',     NULL,     1, 1, 3000121, '91310000MA1FL33X', '上海市浦东新区世纪大道100号', 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000002, 'SALES_CO',     '销售公司',     'COMPANY',   3000001,  1, 1, 3000121, '91310000MA1FL34Y', '上海市黄浦区南京东路200号',  1, 2, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000003, 'MFG_PLANT',    '生产工厂',     'FACTORY',   3000001,  1, 1, 3000121, '91310000MA1FL35Z', '江苏省苏州市工业园300号',    1, 3, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000004, 'HK_BRANCH',    '香港分公司',   'BRANCH',    3000001,  1, 1, 3000122, '61234567-000',     '香港中环德辅道中100号',      1, 4, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000005, 'SH_OFFICE',    '上海办事处',   'OFFICE',    3000002,  0, 1, 3000121, NULL,               '上海市徐汇区漕溪北路500号',  1, 5, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 2. 币别（md_currency）—— 5 行（无外键，先插入供下游引用）
-- ============================================================
REPLACE INTO md_currency (id, code, name, symbol, is_base, decimal_digits, status) VALUES
  (3000121, 'CNY', '人民币',   '¥', 1, 2, 1),
  (3000122, 'USD', '美元',     '$', 0, 2, 1),
  (3000123, 'EUR', '欧元',     '€', 0, 2, 1),
  (3000124, 'JPY', '日元',     '¥', 0, 0, 1),
  (3000125, 'HKD', '港币',     'HK$', 0, 2, 1);


-- ============================================================
-- 3. 计量单位（md_unit）—— 5 行（无外键）
-- ============================================================
REPLACE INTO md_unit (id, code, name, unit_type, is_base, status) VALUES
  (3000161, 'KG',  '千克',     'WEIGHT', 1, 1),
  (3000162, 'M',   '米',       'LENGTH', 1, 1),
  (3000163, 'PCS', '个',       'COUNT',  1, 1),
  (3000164, 'BOX', '箱',       'COUNT',  0, 1),
  (3000165, 'BA',  '包',       'COUNT',  0, 1);


-- ============================================================
-- 4. 部门（sys_dept）—— 5 行
-- ============================================================
REPLACE INTO sys_dept (id, code, name, org_id, parent_id, dept_type, manager_id, status, sort_index) VALUES
  (3000011, 'GEN_OFFICE',  '总经办',     3000001, NULL,     'MANAGE',   3000021, 1, 1),
  (3000012, 'SALES_DEPT',  '销售部',     3000002, NULL,     'BUSINESS', 3000022, 1, 2),
  (3000013, 'PURCHASE',    '采购部',     3000001, NULL,     'BUSINESS', 3000023, 1, 3),
  (3000014, 'FINANCE',     '财务部',     3000001, NULL,     'SUPPORT',  3000024, 1, 4),
  (3000015, 'PRODUCTION',  '生产部',     3000003, NULL,     'PRODUCE',  3000025, 1, 5);


-- ============================================================
-- 5. 员工（sys_employee）—— 5 行
-- ============================================================
REPLACE INTO sys_employee (id, code, name, org_id, dept_id, position, gender, entry_date, is_saler, is_purchaser, mobile, email, active, status, create_by, create_time, update_by, update_time) VALUES
  (3000021, 'EMP001', '张明',  3000001, 3000011, '总经理',     1, '2010-03-01', 0, 0, '13800000001', 'zhang.ming@eerp.com',   1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000022, 'EMP002', '李娜',  3000002, 3000012, '销售经理',   2, '2012-07-15', 1, 0, '13800000002', 'li.na@eerp.com',        1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000023, 'EMP003', '王强',  3000001, 3000013, '采购专员',   1, '2013-09-10', 0, 1, '13800000003', 'wang.qiang@eerp.com',   1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000024, 'EMP004', '刘洋',  3000001, 3000014, '财务主管',   1, '2011-05-20', 0, 0, '13800000004', 'liu.yang@eerp.com',     1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000025, 'EMP005', '陈静',  3000003, 3000015, '生产主管',   2, '2014-02-18', 0, 0, '13800000005', 'chen.jing@eerp.com',    1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 6. 业务员（sys_saler）—— 5 行
-- ============================================================
REPLACE INTO sys_saler (id, code, staff_id, dept_id, is_cal_biz_fee, enabled, create_by, create_time, update_by, update_time, remark) VALUES
  (3000031, 'SAL001', 3000022, 3000012, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '华东区业务员'),
  (3000032, 'SAL002', 3000021, 3000011, 0, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '总经办兼业务'),
  (3000033, 'SAL003', NULL,     3000012, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '华南区业务员'),
  (3000034, 'SAL004', NULL,     3000012, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '华北区业务员'),
  (3000035, 'SAL005', NULL,     3000012, 1, 0, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '已离职业务员');


-- ============================================================
-- 7. 跟单员（sys_merchandiser）—— 4 行
-- ============================================================
REPLACE INTO sys_merchandiser (id, code, staff_id, enabled, create_by, create_time, update_by, update_time, remark) VALUES
  (3000041, 'MER001', 3000022, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '销售跟单'),
  (3000042, 'MER002', 3000025, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '生产跟单'),
  (3000043, 'MER003', NULL,     1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '外协跟单'),
  (3000044, 'MER004', NULL,     0, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '已停用跟单员');


-- ============================================================
-- 8. 物料分组（md_material_group，树形）—— 5 行
-- ============================================================
REPLACE INTO md_material_group (id, code, parent_id, enabled, cn_name, en_name, create_by, create_time, update_by, update_time, remark) VALUES
  (3000081, 'MG_ROOT',    0,        1, '物料分组',     'Material Group',  'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '根节点'),
  (3000082, 'MG_YARN',    3000081,  1, '纱线类',       'Yarn',            'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '纱线大类'),
  (3000083, 'MG_DYE',     3000081,  1, '染料类',       'Dye',             'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '染料大类'),
  (3000084, 'MG_FINISHED',3000081,  1, '成品纱',       'Finished Yarn',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '成品纱子类'),
  (3000085, 'MG_PKG',     3000081,  1, '包装材料',     'Packaging',       'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '包装材料类');


-- ============================================================
-- 9. 物料（md_material）—— 5 行
-- ============================================================
REPLACE INTO md_material (id, code, name, name_en, spec, mat_type, yarn_count, strand, yarn_type, twist, fineness, color, unit_id, batch_flag, vat_flag, tax_rate, purchase_flag, sale_flag, produce_flag, mat_gp_id, is_inventory, status, create_by, create_time, update_by, update_time) VALUES
  (3000071, 'MAT-YARN-32S',  '32S纯棉纱',     '32S Cotton Yarn',       '32支/单股',  'YARN',     32, 1, 'COTTON',  'Z', '32S',  '本色', 3000161, 1, 1, 0.13, 1, 1, 1, 3000082, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000072, 'MAT-YARN-40S',  '40S涤纶纱',     '40S Polyester Yarn',    '40支/单股',  'YARN',     40, 1, 'POLY',    'Z', '40S',  '白色', 3000161, 1, 1, 0.13, 1, 1, 1, 3000082, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000073, 'MAT-YARN-60S',  '60S精梳棉纱',   '60S Combed Cotton',     '60支/双股',  'YARN',     60, 2, 'COTTON',  'S', '60S',  '本色', 3000161, 1, 1, 0.13, 1, 1, 1, 3000084, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000074, 'MAT-YARN-20S',  '20S混纺纱',     '20S Blended Yarn',      '20支/单股',  'YARN',     20, 1, 'BLEND',   'Z', '20S',  '灰色', 3000161, 1, 0, 0.13, 1, 1, 1, 3000082, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000075, 'MAT-DYE-RED',   '活性红染料',    'Reactive Red Dye',      'RGB-3BS',    'DYE',      NULL, NULL, NULL, NULL, NULL, '红色', 3000161, 0, 1, 0.13, 1, 0, 0, 3000083, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 10. 原料分组（md_raw_material_group，树形）—— 5 行
-- ============================================================
REPLACE INTO md_raw_material_group (id, code, parent_id, enabled, cn_name, en_name, create_by, create_time, update_by, update_time, remark) VALUES
  (3000101, 'RMG_ROOT',  0,        1, '原料分组',   'Raw Material Group', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '根节点'),
  (3000102, 'RMG_COTTON',3000101,  1, '棉花类',     'Cotton',             'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '棉纤维'),
  (3000103, 'RMG_WOOL',  3000101,  1, '羊毛类',     'Wool',               'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '动物纤维'),
  (3000104, 'RMG_CHEM',  3000101,  1, '化学纤维',   'Chemical Fiber',     'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '化纤原料'),
  (3000105, 'RMG_BLEND', 3000101,  1, '混纺原料',   'Blended',            'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '混纺纤维');


-- ============================================================
-- 11. 原料（md_raw_material）—— 5 行
-- ============================================================
REPLACE INTO md_raw_material (id, code, name, cn_name, en_name, fineness, s_fee, damp, prd_name, cm_rate, loss_rate, wool_rate, bulk_rate, product_type, group_id, enabled, spin_type, remark, create_by, create_time, update_by, update_time) VALUES
  (3000091, 'RM-COT-001',  '新疆长绒棉',     '新疆长绒棉',  'Xinjiang Long-staple Cotton', '1.25dtex', 5.50,  8.5,  '棉花',  0.95, 0.05, 0.00, 0.00, 'COTTON',     3000102, 1, 'CARD',  '新疆优质长绒棉', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000092, 'RM-WOL-001',  '澳洲美利奴羊毛', '澳洲美利奴',  'Australian Merino Wool',      '19.5um',   8.80, 13.0, '羊毛',  0.92, 0.08, 0.99, 0.00, 'WOOL',       3000103, 1, 'WORSTED','澳洲进口美利奴细毛', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000093, 'RM-PET-001',  '涤纶短纤',       '涤纶短纤',    'Polyester Staple Fiber',      '1.5D*38',  3.20,  0.4,  '涤纶',  0.99, 0.01, 0.00, 0.00, 'POLYESTER',  3000104, 1, 'CARD',  '常规涤纶短纤', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000094, 'RM-VIS-001',  '粘胶短纤',       '粘胶短纤',    'Viscose Staple Fiber',        '1.5D*38',  4.10,  9.0,  '粘胶',  0.97, 0.03, 0.00, 0.00, 'VISCOSE',    3000104, 1, 'CARD',  '环保粘胶纤维', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000095, 'RM-BLD-001',  '涤棉混纺原料',   '涤棉混纺',    'TC Blended Fiber',            '1.5D*38',  4.80,  4.5,  '混纺',  0.98, 0.02, 0.00, 0.00, 'BLEND',      3000105, 1, 'CARD',  'T/C 65/35 混纺', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 12. 原料成分明细（md_raw_material_detail，子表）—— 5 行
-- ============================================================
REPLACE INTO md_raw_material_detail (id, sort_index, raw_mat_id, mat_id, ratio, prd_addr_code, prd_addr_name, fineness, cn_comp, en_comp, yarn_num, fiber_code, fiber_name, fiber_ratio, prd_area, remark) VALUES
  (3000111, 1, 3000095, 3000074, 0.65, 'XJ-A-001', '新疆阿克苏',  '1.25dtex', '棉',     'Cotton',     32, 'COT-001', '棉纤维',     0.65, '中国新疆', '主体纤维'),
  (3000112, 2, 3000095, 3000074, 0.35, 'PET-B-001', '江苏仪征',    '1.5D*38',  '涤纶',   'Polyester',  NULL, 'PET-001', '涤纶纤维',   0.35, '中国江苏', '混纺成分'),
  (3000113, 1, 3000093, 3000072, 1.00, 'PET-B-001', '江苏仪征',    '1.5D*38',  '涤纶',   'Polyester',  40, 'PET-001', '涤纶纤维',   1.00, '中国江苏', '纯涤原料'),
  (3000114, 1, 3000091, 3000071, 1.00, 'XJ-A-001', '新疆阿克苏',   '1.25dtex', '棉',     'Cotton',     32, 'COT-001', '棉纤维',     1.00, '中国新疆', '纯棉原料'),
  (3000115, 1, 3000092, 3000073, 1.00, 'AU-M-001', '澳大利亚',     '19.5um',   '羊毛',   'Wool',       60, 'WOL-001', '羊毛纤维',   1.00, '澳大利亚', '纯毛原料');


-- ============================================================
-- 13. 汇率（md_exchange_rate）—— 5 行
-- ============================================================
REPLACE INTO md_exchange_rate (id, curr_id, rate_type, rate, valid_date, create_by, create_time) VALUES
  (3000131, 3000122, 'BUY',       7.2500,    '2026-01-01', 'system', CURRENT_TIMESTAMP),
  (3000132, 3000122, 'SELL',      7.2800,    '2026-01-01', 'system', CURRENT_TIMESTAMP),
  (3000133, 3000122, 'MID',       7.2650,    '2026-01-01', 'system', CURRENT_TIMESTAMP),
  (3000134, 3000123, 'MID',       7.8500,    '2026-01-01', 'system', CURRENT_TIMESTAMP),
  (3000135, 3000125, 'MID',       0.9280,    '2026-01-01', 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 14. 仓库（md_warehouse）—— 5 行
-- ============================================================
REPLACE INTO md_warehouse (id, code, name, org_id, wh_type, batch_flag, manager_id, address, status) VALUES
  (3000141, 'WH-RAW',     '原料仓',     3000003, 'RAW',      1, 3000025, '江苏省苏州市工业园原料库A区', 1),
  (3000142, 'WH-FIN',     '成品仓',     3000003, 'FINISHED', 1, 3000025, '江苏省苏州市工业园成品库B区', 1),
  (3000143, 'WH-SEMI',    '半成品仓',   3000003, 'SEMI',     0, 3000025, '江苏省苏州市工业园半成品库',   1),
  (3000144, 'WH-DYE',     '染料仓',     3000003, 'HAZARD',   1, 3000023, '江苏省苏州市工业园染料库',     1),
  (3000145, 'WH-PKG',     '包装材料仓', 3000003, 'PACKING',  0, 3000025, '江苏省苏州市工业园包装库',     1);


-- ============================================================
-- 15. 仓位（md_position）—— 5 行
-- ============================================================
REPLACE INTO md_position (id, warehouse_id, code, name, status) VALUES
  (3000151, 3000141, 'A-01', '原料区A-01', 1),
  (3000152, 3000141, 'A-02', '原料区A-02', 1),
  (3000153, 3000142, 'B-01', '成品区B-01', 1),
  (3000154, 3000142, 'B-02', '成品区B-02', 1),
  (3000155, 3000144, 'C-01', '染料区C-01', 1);


-- ============================================================
-- 16. 品牌（md_brand）—— 5 行
-- ============================================================
REPLACE INTO md_brand (id, code, name, status) VALUES
  (3000171, 'BRAND-GF', '金纺',   1),
  (3000172, 'BRAND-YS', '银丝',   1),
  (3000173, 'BRAND-MZ', '棉之源', 1),
  (3000174, 'BRAND-DS', '涤尚',   1),
  (3000175, 'BRAND-YZ', '羊之选', 1);


-- ============================================================
-- 17. 色系（md_color_series）—— 5 行
-- ============================================================
REPLACE INTO md_color_series (id, code, enabled, cn_name, create_by, create_time, update_by, update_time, remark) VALUES
  (3000181, 'CS-WARM',   1, '暖色系',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '红黄橙系'),
  (3000182, 'CS-COOL',   1, '冷色系',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '蓝绿紫系'),
  (3000183, 'CS-NEUTRAL',1, '中性色系', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '黑白灰系'),
  (3000184, 'CS-POP',    1, '流行色系', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '当季流行'),
  (3000185, 'CS-CLASS',  1, '经典色系', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '常销经典');


-- ============================================================
-- 18. 公司色号（md_comp_color）—— 5 行
-- ============================================================
REPLACE INTO md_comp_color (id, code, color_sys_id, cn_name, is_ab_yarn, color_name, enabled, create_by, create_time, update_by, update_time, remark) VALUES
  (3000191, 'CC-001', 3000181, '大红', 0, 'Red',        1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '暖色系'),
  (3000192, 'CC-002', 3000182, '海蓝', 0, 'Ocean Blue', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '冷色系'),
  (3000193, 'CC-003', 3000181, '翠绿', 0, 'Emerald',    1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '暖色系'),
  (3000194, 'CC-004', 3000183, '墨黑', 0, 'Ink Black',  1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '中性'),
  (3000195, 'CC-005', 3000182, 'AB蓝白', 1, 'AB Blue',  1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, 'AB纱色号');


-- ============================================================
-- 19. 打版色号（md_print_color）—— 5 行
-- ============================================================
REPLACE INTO md_print_color (id, code, cn_name, enabled, comp_color_id, color_sys_id, color_name, dye_method_id, create_by, create_time, update_by, update_time, remark) VALUES
  (3000201, 'PC-001', '大红版',   1, 3000191, 3000181, 'Red Print',        'DM-REACTIVE', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '活性染料打版'),
  (3000202, 'PC-002', '海蓝版',   1, 3000192, 3000182, 'Ocean Blue Print', 'DM-REACTIVE', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '活性染料打版'),
  (3000203, 'PC-003', '翠绿版',   1, 3000193, 3000181, 'Emerald Print',    'DM-DIRECT',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '直接染料打版'),
  (3000204, 'PC-004', '墨黑版',   1, 3000194, 3000183, 'Ink Black Print',  'DM-SULFUR',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, '硫化染料打版'),
  (3000205, 'PC-005', 'AB蓝白版', 1, 3000195, 3000182, 'AB Blue Print',    'DM-REACTIVE', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP, 'AB纱打版');


-- ============================================================
-- 20. 集锦卡（md_hl_card）—— 5 行
-- ============================================================
REPLACE INTO md_hl_card (id, code, name, mat_id, yarn_count, strand, twist, fineness, color_id, craft_desc, cn_name, en_name, sp_req, sp_price, remark, status, create_by, create_time, update_by, update_time) VALUES
  (3000211, 'HL-001', '32S纯棉工艺卡',   3000071, 32, 1, 'Z',  '32S', 3000194, '环锭纺，捻度850',  '32S纯棉',  '32S Cotton',   '国标一等', 5.50,  '常规纯棉工艺', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000212, 'HL-002', '40S涤纶工艺卡',   3000072, 40, 1, 'Z',  '40S', 3000192, '环锭纺，捻度950',  '40S涤纶',  '40S Polyester','国标一等', 4.20,  '常规涤纶工艺', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000213, 'HL-003', '60S精梳工艺卡',   3000073, 60, 2, 'S',  '60S', 3000191, '精梳，双股，捻度1200', '60S精梳棉','60S Combed',  '国标优等', 8.80,  '高端精梳工艺', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000214, 'HL-004', '20S混纺工艺卡',   3000074, 20, 1, 'Z',  '20S', 3000194, 'T/C 65/35，捻度750',  '20S混纺',  '20S Blended',  '行业标准A',3.80,  '常规混纺工艺', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000215, 'HL-005', '80S羊绒混纺卡',   3000075, 80, 2, 'S',  '80S', 3000195, '羊绒20%混纺，精梳',   '80S羊绒',  '80S Cashmere', '客户标准', 15.50, '高端羊绒混纺', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 21. 贸易类型（md_trade_type）—— 5 行
-- ============================================================
REPLACE INTO md_trade_type (id, code, name, name_en, trade_kind, status) VALUES
  (3000221, 'TT-001', '一般贸易',   'General Trade',       'GENERAL', 1),
  (3000222, 'TT-002', '来料加工',   'Processing with Supplied Materials', 'INCOMING', 1),
  (3000223, 'TT-003', '进料加工',   'Processing with Imported Materials', 'IMPORTED', 1),
  (3000224, 'TT-004', '边境贸易',   'Border Trade',        'BORDER',  1),
  (3000225, 'TT-005', '转口贸易',   'Entrepot Trade',      'ENTREPOT',1);


-- ============================================================
-- 22. 港口（md_harbour）—— 5 行
-- ============================================================
REPLACE INTO md_harbour (id, code, name_cn, name_en, country, status) VALUES
  (3000231, 'SH',  '上海港', 'Shanghai',  '中国', 1),
  (3000232, 'NB',  '宁波港', 'Ningbo',    '中国', 1),
  (3000233, 'GZ',  '广州港', 'Guangzhou', '中国', 1),
  (3000234, 'QD',  '青岛港', 'Qingdao',   '中国', 1),
  (3000235, 'HK',  '香港港', 'Hong Kong', '中国', 1);


-- ============================================================
-- 23. 印章（md_seal）—— 5 行
-- ============================================================
REPLACE INTO md_seal (id, code, stamp_name, company_id, stamp_admin, create_by, create_time, update_by, update_time) VALUES
  (3000241, 'SEAL-001', '总公司公章',   3000001, 3000021, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000242, 'SEAL-002', '总公司合同章', 3000001, 3000022, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000243, 'SEAL-003', '总公司财务章', 3000001, 3000024, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000244, 'SEAL-004', '销售公司出库章', 3000002, 3000022, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000245, 'SEAL-005', '香港分公司发票章', 3000004, NULL, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 24. 箱贴模板（md_box_label_tpl）—— 5 行
--    注意：create_by 列为 NOT NULL，必须提供值
-- ============================================================
REPLACE INTO md_box_label_tpl (id, code, cn_name, en_name, org_id, is_en_print, enabled, remark, create_by, create_time, update_by, update_time) VALUES
  (3000251, 'BLT-001', '标准箱贴',     'Standard Box Label',  3000001, 0, 1, '国内标准箱贴模板',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000252, 'BLT-002', '出口箱贴',     'Export Box Label',    3000001, 1, 1, '英文出口箱贴模板',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000253, 'BLT-003', '内销箱贴',     'Domestic Box Label',  3000002, 0, 1, '内销专用箱贴',       'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000254, 'BLT-004', '特殊箱贴',     'Special Box Label',   3000003, 0, 1, '特殊规格箱贴',       'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000255, 'BLT-005', '礼品箱贴',     'Gift Box Label',      3000002, 1, 0, '礼品包装专用箱贴',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 25. 质量标准（md_quality_std）—— 5 行
-- ============================================================
REPLACE INTO md_quality_std (id, code, name, std_desc, status) VALUES
  (3000261, 'QS-001', '国标一等品', 'FZ/T 12004 纺织品一等品标准：条干均匀、无明显疵点', 1),
  (3000262, 'QS-002', '国标优等品', 'FZ/T 12004 纺织品优等品标准：条干极均匀、无疵点',  1),
  (3000263, 'QS-003', '行业标准A',  '行业A类标准：满足高端面料用纱要求',                  1),
  (3000264, 'QS-004', '客户标准',   '按客户合同约定的特殊技术指标',                       1),
  (3000265, 'QS-005', '出口标准',   '满足出口目的国技术法规要求',                         1);


-- ============================================================
-- 26. 结算方式（md_firp_type）—— 5 行
-- ============================================================
REPLACE INTO md_firp_type (id, code, name, firp_kind, status) VALUES
  (3000271, 'FP-001', '电汇',     'TT',     1),
  (3000272, 'FP-002', '票汇',     'DD',     1),
  (3000273, 'FP-003', '信用证',   'LC',     1),
  (3000274, 'FP-004', '托收',     'COLLECT',1),
  (3000275, 'FP-005', '现金',     'CASH',   1);


-- ============================================================
-- 27. 特殊纺工费主表（md_spin_fee）—— 3 行
-- ============================================================
REPLACE INTO md_spin_fee (id, code, remark, create_by, create_time, update_by, update_time) VALUES
  (3000281, 'SF-001', '精梳棉纱特殊纺工费方案', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000282, 'SF-002', '混纺纱特殊纺工费方案',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000283, 'SF-003', '羊绒混纺特殊纺工费方案', 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 28. 特殊纺工费关联物料（md_spin_fee_material，子表）—— 3 行
-- ============================================================
REPLACE INTO md_spin_fee_material (id, sort_index, spin_fee_id, mat_id) VALUES
  (3000291, 1, 3000281, 3000073),
  (3000292, 1, 3000282, 3000074),
  (3000293, 1, 3000283, 3000075);


-- ============================================================
-- 29. 特殊纺工费关联原料（md_spin_fee_raw_material，子表）—— 3 行
-- ============================================================
REPLACE INTO md_spin_fee_raw_material (id, sort_index, spin_fee_id, raw_mat_id, s_fee) VALUES
  (3000301, 1, 3000281, 3000091, 5.50),
  (3000302, 1, 3000282, 3000095, 4.80),
  (3000303, 1, 3000283, 3000092, 15.50);


-- ============================================================
-- 30. 客户（md_customer）—— 5 行
-- ============================================================
REPLACE INTO md_customer (id, code, name, name_en, short_name, cust_type, curr_id, sal_org_id, saler_id, credit_limit, credit_period, tax_rate, tax_no, firp_type, contact, phone, email, address, bank_name, bank_account, is_credit_check, allow_sale, status, create_by, create_time, update_by, update_time) VALUES
  (3000051, 'CUST-001', '江苏纺织有限公司',     'Jiangsu Textile Co., Ltd.',     '江苏纺织', 'GENERAL',   3000121, 3000002, 3000031, 5000000.00, 60, 0.13, '91320100MA1ABC01', 'FP-001', '王经理', '13900000001', 'sales@js-textile.com',     '江苏省南京市中央路1号',    '中国银行南京分行', '6228480010001234561', 1, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000052, 'CUST-002', '浙江印染厂',           'Zhejiang Dyeing Factory',       '浙江印染', 'GENERAL',   3000121, 3000002, 3000033, 3000000.00, 45, 0.13, '91330100MA1ABC02', 'FP-001', '李总',   '13900000002', 'sales@zj-dyeing.com',      '浙江省杭州市西湖区',       '工商银行杭州分行', '6228480010001234562', 1, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000053, 'CUST-003', '广东服装厂',           'Guangdong Garment Factory',     '广东服装', 'GENERAL',   3000121, 3000002, 3000034, 2000000.00, 30, 0.13, '91440100MA1ABC03', 'FP-003', '陈总',   '13900000003', 'sales@gd-garment.com',     '广东省广州市天河区',       '建设银行广州分行', '6228480010001234563', 1, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000054, 'CUST-004', '上海纺织品进出口公司', 'Shanghai Textile Import & Export','上海纺织进出口', 'IMPORT', 3000122, 3000002, 3000031, 1000000.00, 90, 0.13, '91310100MA1ABC04', 'FP-003', '刘经理', '13900000004', 'sales@sh-tex.com',         '上海市黄浦区外滩',         '交通银行上海分行', '6228480010001234564', 0, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000055, 'CUST-005', '福建针织厂',           'Fujian Knitting Factory',       '福建针织', 'GENERAL',   3000121, 3000002, 3000033, 800000.00,  30, 0.13, '91350100MA1ABC05', 'FP-001', '黄经理', '13900000005', 'sales@fj-knit.com',        '福建省福州市鼓楼区',       '农业银行福州分行', '6228480010001234565', 0, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 31. 供应商（md_supplier）—— 5 行
-- ============================================================
REPLACE INTO md_supplier (id, code, name, name_en, short_name, sup_type, curr_id, pur_org_id, purchaser_id, tax_rate, tax_no, firp_type, pay_type, contact, phone, email, address, bank_name, bank_account, status, create_by, create_time, update_by, update_time) VALUES
  (3000061, 'SUP-001', '江苏纱线原料厂',       'Jiangsu Yarn Material Factory',  '江苏纱线厂', 'RAW',     3000121, 3000001, 3000023, 0.13, '91320100MA1SUP01', 'FP-001', 'TT',     '赵经理', '13700000001', 'sales@js-yarn.com',     '江苏省苏州市吴中区',     '中国银行苏州分行', '6228480020001234561', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000062, 'SUP-002', '浙江染料化工公司',     'Zhejiang Dye Chemical Co.',      '浙江染料',   'DYE',     3000121, 3000001, 3000023, 0.13, '91330100MA1SUP02', 'FP-001', 'TT',     '钱经理', '13700000002', 'sales@zj-dye.com',      '浙江省杭州市萧山区',     '工商银行杭州分行', '6228480020001234562', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000063, 'SUP-003', '上海化工厂',           'Shanghai Chemical Plant',        '上海化工',   'DYE',     3000121, 3000001, 3000023, 0.13, '91310100MA1SUP03', 'FP-003', 'LC',     '孙经理', '13700000003', 'sales@sh-chem.com',     '上海市金山区化工区',     '建设银行上海分行', '6228480020001234563', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000064, 'SUP-004', '澳洲羊毛进口公司',     'Australia Wool Import Co.',      '澳洲羊毛',   'RAW',     3000122, 3000001, 3000023, 0.00, 'AU-001',           'FP-003', 'LC',     'John',   '61300000001', 'sales@au-wool.com',     'Melbourne VIC 3000',     'ANZ Bank',          '6228480020001234564', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000065, 'SUP-005', '山东纺织机械公司',     'Shandong Textile Machinery',     '山东纺机',   'EQUIP',   3000121, 3000001, 3000023, 0.13, '91370100MA1SUP05', 'FP-004', 'TT',     '周经理', '13700000005', 'sales@sd-mach.com',     '山东省济南市高新区',     '农业银行济南分行', '6228480020001234565', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 32. 信用管理主表（md_credit）—— 3 行
-- ============================================================
REPLACE INTO md_credit (id, code, org_id, is_group_credit, cust_type, remark, create_by, create_time, update_by, update_time) VALUES
  (3000311, 'CR-001', 3000001, 0, 0, '内销客户信用方案',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000312, 'CR-002', 3000001, 0, 1, '出口客户信用方案',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000313, 'CR-003', 3000001, 1, 0, '集团统一信用方案',   'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 33. 信用管理客户明细（md_credit_detail，子表）—— 5 行
-- ============================================================
REPLACE INTO md_credit_detail (id, sort_index, credit_id, cust_id, curr_id, amount, amount_status, valid_time, credit_status, overdue_days, remark) VALUES
  (3000321, 1, 3000311, 3000051, 3000121, 5000000.00, 'NORMAL', '2026-01-01', 'NORMAL',    0,  '正常额度'),
  (3000322, 2, 3000311, 3000052, 3000121, 3000000.00, 'NORMAL', '2026-01-01', 'NORMAL',    0,  '正常额度'),
  (3000323, 1, 3000312, 3000054, 3000122, 1000000.00, 'NORMAL', '2026-01-01', 'NORMAL',    0,  '出口额度'),
  (3000324, 1, 3000313, 3000053, 3000121, 2000000.00, 'FROZEN', '2026-01-01', 'OVERDUE',   15, '逾期冻结'),
  (3000325, 2, 3000313, 3000055, 3000121, 800000.00,  'NORMAL', '2026-01-01', 'NORMAL',    0,  '正常额度');


-- ============================================================
-- 34. 数据字典主表（sys_dict）—— 5 行
--    表结构见 schema-h2-master-ext.sql（id 主键）
-- ============================================================
REPLACE INTO sys_dict (id, dict_code, dict_name, remark, status, create_by, create_time, update_by, update_time) VALUES
  (3000331, 'cust_type',    '客户类型', '客户分类字典',     1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000332, 'mat_type',     '物料类型', '物料分类字典',     1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000333, 'wh_type',      '仓库类型', '仓库分类字典',     1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000334, 'trade_kind',   '贸易种类', '贸易类型分类字典', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3000335, 'firp_kind',    '结算种类', '结算方式分类字典', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 35. 数据字典项（sys_dict_item，子表）—— 5 行
-- ============================================================
REPLACE INTO sys_dict_item (id, dict_id, item_code, item_name, sort_index, enabled, remark) VALUES
  (3000341, 3000331, 'GENERAL',  '普通客户',     1, 1, '一般贸易客户'),
  (3000342, 3000331, 'IMPORT',   '进出口客户',   2, 1, '进出口贸易客户'),
  (3000343, 3000332, 'YARN',     '纱线',         1, 1, '纱线类物料'),
  (3000344, 3000332, 'DYE',      '染料',         2, 1, '染料类物料'),
  (3000345, 3000332, 'FINISHED', '成品',         3, 1, '成品类物料');


-- ============================================================
-- 文件统计
--   主表（30 张）+ 子表（5 张）= 35 张表
--   sys_org                   : 5 行 (3000001-3000005)
--   sys_dept                  : 5 行 (3000011-3000015)
--   sys_employee              : 5 行 (3000021-3000025)
--   sys_saler                 : 5 行 (3000031-3000035)
--   sys_merchandiser          : 4 行 (3000041-3000044)
--   md_customer               : 5 行 (3000051-3000055)
--   md_supplier               : 5 行 (3000061-3000065)
--   md_material               : 5 行 (3000071-3000075)
--   md_material_group         : 5 行 (3000081-3000085)
--   md_raw_material           : 5 行 (3000091-3000095)
--   md_raw_material_group     : 5 行 (3000101-3000105)
--   md_raw_material_detail    : 5 行 (3000111-3000115)  [子表]
--   md_currency               : 5 行 (3000121-3000125)
--   md_exchange_rate          : 5 行 (3000131-3000135)
--   md_warehouse              : 5 行 (3000141-3000145)
--   md_position               : 5 行 (3000151-3000155)
--   md_unit                   : 5 行 (3000161-3000165)
--   md_brand                  : 5 行 (3000171-3000175)
--   md_color_series           : 5 行 (3000181-3000185)
--   md_comp_color             : 5 行 (3000191-3000195)
--   md_print_color            : 5 行 (3000201-3000205)
--   md_hl_card                : 5 行 (3000211-3000215)
--   md_trade_type             : 5 行 (3000221-3000225)
--   md_harbour                : 5 行 (3000231-3000235)
--   md_seal                   : 5 行 (3000241-3000245)
--   md_box_label_tpl          : 5 行 (3000251-3000255)
--   md_quality_std            : 5 行 (3000261-3000265)
--   md_firp_type              : 5 行 (3000271-3000275)
--   md_spin_fee               : 3 行 (3000281-3000283)
--   md_spin_fee_material      : 3 行 (3000291-3000293)  [子表]
--   md_spin_fee_raw_material  : 3 行 (3000301-3000303)  [子表]
--   md_credit                 : 3 行 (3000311-3000313)
--   md_credit_detail          : 5 行 (3000321-3000325)  [子表]
--   sys_dict                  : 5 行 (3000331-3000335)
--   sys_dict_item             : 5 行 (3000341-3000345)  [子表]
--   合计                      : 163 行 REPLACE
--   ID 区间                   : 3000001 - 3000345
-- ============================================================

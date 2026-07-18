/**
 * EERP 基础资料（主数据 MDM）模块。
 *
 * <p>包含组织/部门/员工/客户/供应商/物料/币别/汇率/仓库/单位等 30 个主数据 bo_code，
 * 提供 {@code AbstractMasterDataService} / {@code AbstractTreeMasterDataService} /
 * {@code AbstractCreditQueryService} 等抽象类与查询契约。</p>
 *
 * <p>对应表结构：{@code 01-基础资料表.sql}（35 张表）</p>
 * <p>对应设计文档：{@code 设计文档/06-基础资料/01-基础资料管理设计.md}</p>
 */
package com.eerp.master;

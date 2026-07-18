/**
 * EERP 供应链管理模块。
 *
 * <p>包含 5 个子模块：</p>
 * <ul>
 *   <li>{@code com.eerp.scm.pur} — 采购管理（采购申请/合同/订单/收料/入库/退料/发票）</li>
 *   <li>{@code com.eerp.scm.sal} — 销售管理（内销合同/报价/合同/订单/发货/出库/退货/发票/打样）</li>
 *   <li>{@code com.eerp.scm.inv} — 库存管理（即时库存/批次/盘点/调拨/形态转换/出入库/锁库）</li>
 *   <li>{@code com.eerp.scm.price} — 价格管理（价格表/阶梯价）</li>
 *   <li>{@code com.eerp.scm.credit} — 信用管理（客户信用额度）</li>
 *   <li>{@code com.eerp.scm.sn} — 序列号管理（条码）</li>
 * </ul>
 *
 * <p>对应表结构：{@code 02-CRM销售表.sql} + {@code 03-采购管理表.sql} + {@code 04-库存管理表.sql}</p>
 * <p>对应设计文档：{@code 设计文档/02-供应链管理/}</p>
 */
package com.eerp.scm;

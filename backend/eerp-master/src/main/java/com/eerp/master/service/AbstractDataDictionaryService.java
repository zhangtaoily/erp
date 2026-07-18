package com.eerp.master.service;

import java.util.List;
import java.util.Map;

/**
 * 数据字典缓存契约（对齐设计文档 06 §3.6）。
 *
 * <p>数据字典（sys_dict / sys_dict_item）与平台元数据枚举（meta_enum / meta_enum_item）的边界：</p>
 * <ul>
 *   <li>meta_enum：系统级枚举（字段类型、控件类型、状态码等），由平台基座管理</li>
 *   <li>sys_dict：业务级字典（贸易类型、结算方式、客户类型等），由本模块管理</li>
 * </ul>
 *
 * <p>数据字典支持缓存加速，主数据变更时通过 syncToMetaField 同步到表单元数据字段。</p>
 */
public abstract class AbstractDataDictionaryService {

    /**
     * 获取字典定义。
     *
     * @param dictCode 字典编码
     * @return 字典定义 {code, name, remark}
     */
    public abstract Map<String, Object> getDict(String dictCode);

    /**
     * 列出字典的所有项。
     *
     * @param dictCode 字典编码
     * @return 字典项列表 [{itemCode, itemName, sortIndex, ...}]
     */
    public abstract List<Map<String, Object>> listItems(String dictCode);

    /**
     * 保存字典定义（新增或更新）。
     *
     * @param dict 字典定义
     * @return 字典ID
     */
    public abstract Long saveDict(Map<String, Object> dict);

    /**
     * 保存字典项（新增或更新）。
     *
     * @param item 字典项
     * @return 字典项ID
     */
    public abstract Long saveItem(Map<String, Object> item);

    /**
     * 将字典项同步到表单元数据字段（meta_form_field 的 enum_source）。
     *
     * <p>当字典项变更时，调用此方法同步更新引用该字典的表单字段，
     * 确保前端渲染的选项列表与字典一致。</p>
     *
     * @param tableName  表名
     * @param fieldName  字段名
     */
    public abstract void syncToMetaField(String tableName, String fieldName);

    /**
     * 清除字典缓存（字典项变更后调用）。
     *
     * @param dictCode 字典编码（null 表示清除全部字典缓存）
     */
    public abstract void clearCache(String dictCode);
}

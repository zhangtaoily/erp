package com.eerp.master.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 物料多单位换算契约（对齐设计文档 06 §3.4）。
 *
 * <p>被销售管理、采购管理、库存管理、生产制造引用，提供统一的数量换算口径。</p>
 *
 * <p>换算逻辑：物料（md_material）配置基本单位（unit_id），
 * 通过 md_unit_conv 表维护物料×源单位×目标单位的换算率。</p>
 */
public abstract class AbstractUnitConversionService {

    /**
     * 数量单位换算。
     *
     * @param matId      物料ID
     * @param fromUnitId 源单位ID
     * @param toUnitId   目标单位ID
     * @param qty        源数量
     * @return 目标单位下的数量
     */
    public abstract BigDecimal convert(Long matId, Long fromUnitId, Long toUnitId, BigDecimal qty);

    /**
     * 列出物料的全部单位换算配置。
     *
     * @param matId 物料ID
     * @return 换算配置列表（fromUnit/toUnit/rate）
     */
    public abstract List<Map<String, Object>> listConversions(Long matId);

    /**
     * 获取单条换算配置。
     *
     * @param matId      物料ID
     * @param fromUnitId 源单位ID
     * @param toUnitId   目标单位ID
     * @return 换算配置 {fromUnitId, toUnitId, rate}，无配置返回 null
     */
    public abstract Map<String, Object> getConversion(Long matId, Long fromUnitId, Long toUnitId);

    /**
     * 判断是否为基本单位。
     *
     * @param unitId 单位ID
     * @return true=基本单位
     */
    public abstract boolean isBaseUnit(Long unitId);

    /**
     * 获取物料的基本单位ID。
     *
     * @param matId 物料ID
     * @return 基本单位ID
     */
    public abstract Long getBaseUnit(Long matId);
}

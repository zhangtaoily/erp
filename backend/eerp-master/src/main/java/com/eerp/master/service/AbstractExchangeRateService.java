package com.eerp.master.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;

/**
 * 汇率取值契约（对齐设计文档 06 §3.5）。
 *
 * <p>被财务会计（应收/应付/凭证）、税务管理引用，提供统一的汇率取值口径。</p>
 *
 * <p>汇率表 md_exchange_rate 按币别×日期×类型（买入/卖出/中间）三维度记录，
     * 取值时按 valid_date 倒序取最近生效的一条。</p>
 */
public abstract class AbstractExchangeRateService {

    /**
     * 取指定币别、日期、类型的汇率。
     *
     * @param currId   币别ID
     * @param date     业务日期
     * @param rateType 汇率类型（buy买入/sell卖出/mid中间）
     * @return 汇率值，无匹配返回 null
     */
    public abstract BigDecimal getRate(Long currId, LocalDate date, String rateType);

    /**
     * 取指定币别、日期的最近生效汇率（默认取中间价 mid）。
     *
     * @param currId 币别ID
     * @param date   业务日期
     * @return 汇率值
     */
    public abstract BigDecimal getEffectiveRate(Long currId, LocalDate date);

    /**
     * 取三档汇率（buy/sell/mid），用于多币种业务场景。
     *
     * @param currId 币别ID
     * @param date   业务日期
     * @return {buy: x, sell: y, mid: z}
     */
    public abstract Map<String, BigDecimal> getTripleRate(Long currId, LocalDate date);

    /**
     * 取本位币对目标币别的汇率（自动判断方向）。
     *
     * @param baseCurrId 本位币ID
     * @param tgtCurrId  目标币别ID
     * @param date       业务日期
     * @return 汇率值
     */
    public abstract BigDecimal getCrossRate(Long baseCurrId, Long tgtCurrId, LocalDate date);
}

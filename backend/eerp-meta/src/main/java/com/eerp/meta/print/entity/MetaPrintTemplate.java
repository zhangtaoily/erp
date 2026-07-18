package com.eerp.meta.print.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 打印模板元数据，对应表 meta_print_template。
 *
 * <p>对齐设计文档 02 §5.4.1。类 Excel 模板，由 {@code AbstractPrintTemplateService} 渲染。</p>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_print_template")
public class MetaPrintTemplate extends BaseEntity {

    /** 模板编码（唯一） */
    private String templateCode;

    /** 模板名称 */
    private String templateName;

    /** 业务对象编码 */
    private String boCode;

    /** 模板类型：single 单据 / batch 套打 */
    private String templateType;

    /** 语言（zh/en） */
    private String lang;

    /** 纸张类型：A4 / A5 / letter / custom */
    private String paperType;

    /** 自定义纸张宽（mm） */
    private Integer paperWidth;

    /** 自定义纸张高（mm） */
    private Integer paperHeight;

    /** 方向：portrait 纵向 / landscape 横向 */
    private String orientation;

    /** 页边距 JSON：{top/bottom/left/right/header/footer} */
    private String marginJson;

    /** 画布行数 */
    private Integer rowCount;

    /** 画布列数 */
    private Integer colCount;

    /** 单元格定义 JSON：Record<"r_c", PrintCell>，含 content/cell_type/field_code/expand/style */
    private String cellsJson;

    /** 合并信息 JSON：Record<"r_c", {rowspan, colspan}> */
    private String mergesJson;

    /** 行带 JSON：[{band: title/header/detail/summary, row: n}] */
    private String rowBandsJson;

    /** 是否默认模板：0否 1是 */
    private Integer isDefault;

    /** 启用状态：0停用 1启用（由 00c-平台元数据扩展补全.sql ALTER TABLE 添加） */
    private Integer isEnable;
}

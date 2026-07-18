package com.eerp.bos.print;

/**
 * 打印单元格类型（对齐设计文档 02 §5.4.1 cells_json 的 cell_type 字段）。
 */
public enum PrintCellType {

    /** 静态文本 */
    TEXT,

    /** 字段引用（按 field_code 取值） */
    FIELD,

    /** 公式（按 content 求值，如 =SUM(detail.qty)） */
    FORMULA,

    /** 图片 */
    IMAGE,

    /** 二维码 */
    BARCODE;

    /**
     * 按编码解析（不区分大小写，未知返回 TEXT）。
     */
    public static PrintCellType fromCode(String code) {
        if (code == null || code.trim().isEmpty()) {
            return TEXT;
        }
        try {
            return valueOf(code.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return TEXT;
        }
    }
}

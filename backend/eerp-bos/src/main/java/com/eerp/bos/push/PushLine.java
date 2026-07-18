package com.eerp.bos.push;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 下推行（源单行勾选 + 本次下推量）。
 */
@Data
public class PushLine {

    /** 源单行ID */
    private Long lineId;

    /** 本次下推量 */
    private BigDecimal pushQty;

    public PushLine() {
    }

    public PushLine(Long lineId, BigDecimal pushQty) {
        this.lineId = lineId;
        this.pushQty = pushQty;
    }
}

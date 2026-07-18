package com.eerp.meta.bo.vo;

import com.eerp.meta.bo.entity.MetaBusinessObject;
import com.eerp.meta.entity.dto.FormEntityDTO;
import com.eerp.meta.layout.entity.MetaFormLayout;
import lombok.Data;

import java.util.List;

/**
 * 表单元数据聚合 VO（BusinessObject + 实体列表含字段 + 默认布局）
 */
@Data
public class FormMetaVO {

    /** 业务对象定义 */
    private MetaBusinessObject businessObject;

    /** 实体列表（含字段） */
    private List<FormEntityDTO> entities;

    /** 默认表单布局 */
    private MetaFormLayout layout;
}

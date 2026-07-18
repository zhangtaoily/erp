package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_seal")
public class MdSeal extends BaseEntity {

    private String code;

    private String stampName;

    private Long companyId;

    private Long stampAdmin;
}

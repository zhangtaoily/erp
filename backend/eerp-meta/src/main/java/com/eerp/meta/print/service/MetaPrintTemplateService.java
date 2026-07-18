package com.eerp.meta.print.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.print.entity.MetaPrintTemplate;

import java.util.List;

/**
 * 打印模板元数据 Service
 */
public interface MetaPrintTemplateService extends IService<MetaPrintTemplate> {

    /** 按业务对象编码查询启用的模板列表 */
    List<MetaPrintTemplate> listByBoCode(String boCode);

    /** 获取业务对象的默认模板（is_default=1） */
    MetaPrintTemplate getDefault(String boCode);
}

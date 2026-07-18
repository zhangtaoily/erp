package com.eerp.meta.layout.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.layout.entity.MetaFormLayout;

/**
 * 表单布局 Service
 */
public interface MetaFormLayoutService extends IService<MetaFormLayout> {

    /**
     * 获取业务对象的默认布局
     */
    MetaFormLayout getDefault(String boCode);
}

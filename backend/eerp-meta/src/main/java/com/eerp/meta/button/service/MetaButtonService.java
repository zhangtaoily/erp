package com.eerp.meta.button.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.button.entity.MetaButton;
import com.eerp.meta.button.entity.MetaFormButton;

import java.util.List;

/**
 * 按钮 Service
 */
public interface MetaButtonService extends IService<MetaButton> {

    /**
     * 按业务对象编码查询按钮定义列表（通过表单按钮绑定关联）
     */
    List<MetaButton> listByBoCode(String boCode);

    /**
     * 按业务对象编码查询表单按钮绑定列表（含可用性矩阵）
     */
    List<MetaFormButton> listFormButtons(String boCode);
}

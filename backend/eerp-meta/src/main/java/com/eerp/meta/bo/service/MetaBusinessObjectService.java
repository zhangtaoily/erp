package com.eerp.meta.bo.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.bo.entity.MetaBusinessObject;

/**
 * 业务对象 Service
 */
public interface MetaBusinessObjectService extends IService<MetaBusinessObject> {

    /**
     * 根据业务对象编码查询
     */
    MetaBusinessObject getByBoCode(String boCode);
}

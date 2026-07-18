package com.eerp.bos.form;

import com.eerp.meta.bo.vo.FormMetaVO;

/**
 * 表单元数据服务抽象基类
 */
public abstract class AbstractFormMetaService {

    /**
     * 获取表单元数据聚合 VO
     */
    public abstract FormMetaVO getFormMeta(String boCode);

    /**
     * 清除指定业务对象的表单元数据缓存
     */
    public abstract void evictCache(String boCode);
}

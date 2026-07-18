package com.eerp.bos.form;

import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.cache.FormMetaCache;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 表单元数据服务实现：基于 {@link FormMetaCache} 提供元数据访问与缓存失效
 */
@Service
public class FormMetaServiceImpl extends AbstractFormMetaService {

    @Autowired
    private FormMetaCache formMetaCache;

    @Override
    public FormMetaVO getFormMeta(String boCode) {
        return formMetaCache.get(boCode);
    }

    @Override
    public void evictCache(String boCode) {
        formMetaCache.evict(boCode);
    }
}

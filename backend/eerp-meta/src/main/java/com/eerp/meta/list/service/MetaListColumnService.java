package com.eerp.meta.list.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.list.entity.MetaListColumn;

import java.util.List;

/**
 * 列表列定义 Service
 */
public interface MetaListColumnService extends IService<MetaListColumn> {

    /**
     * 按业务对象编码查询列定义列表
     */
    List<MetaListColumn> listByBoCode(String boCode);
}

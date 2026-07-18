package com.eerp.bos.list;

import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;

import java.util.Map;

/**
 * 列表查询服务抽象基类
 */
public abstract class AbstractListService {

    /**
     * 分页查询
     *
     * @param boCode      业务对象编码
     * @param pageRequest 分页请求
     * @param params      查询参数（key=字段编码，value=值或 {op,value} 结构）
     */
    public abstract PageResult<Map<String, Object>> page(String boCode, PageRequest pageRequest, Map<String, Object> params);
}

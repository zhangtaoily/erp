package com.eerp.api.sys.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.api.sys.entity.SysOrg;

import java.util.List;

public interface SysOrgService extends IService<SysOrg> {

    /**
     * 返回组织树（扁平列表，按 parent_id、sort_index 排序，前端按 parent_id 组装树）
     */
    List<SysOrg> tree();
}

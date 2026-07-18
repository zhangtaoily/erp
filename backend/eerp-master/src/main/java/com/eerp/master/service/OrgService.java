package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.SysOrg;
import com.eerp.master.mapper.MdOrgMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 组织主数据服务（树形，bo_code=MD_ORG，表 sys_org）。
 */
@Service
public class OrgService extends AbstractTreeMasterDataService<SysOrg> {

    @Autowired
    private MdOrgMapper mdOrgMapper;

    @Override
    protected String boCode() {
        return "MD_ORG";
    }

    @Override
    protected BaseMapper<SysOrg> mapper() {
        return mdOrgMapper;
    }

    @Override
    protected String tableName() {
        return "sys_org";
    }

    @Override
    protected Long getParentId(SysOrg entity) {
        return entity.getParentId();
    }

    @Override
    protected Long getId(SysOrg entity) {
        return entity.getId();
    }

    @Override
    protected String getName(SysOrg entity) {
        return entity.getName();
    }
}

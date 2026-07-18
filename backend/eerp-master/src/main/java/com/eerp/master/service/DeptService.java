package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.SysDept;
import com.eerp.master.mapper.MdDeptMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 部门主数据服务（树形，bo_code=MD_DEPT，表 sys_dept）。
 */
@Service
public class DeptService extends AbstractTreeMasterDataService<SysDept> {

    @Autowired
    private MdDeptMapper mdDeptMapper;

    @Override
    protected String boCode() {
        return "MD_DEPT";
    }

    @Override
    protected BaseMapper<SysDept> mapper() {
        return mdDeptMapper;
    }

    @Override
    protected String tableName() {
        return "sys_dept";
    }

    @Override
    protected Long getParentId(SysDept entity) {
        return entity.getParentId();
    }

    @Override
    protected Long getId(SysDept entity) {
        return entity.getId();
    }

    @Override
    protected String getName(SysDept entity) {
        return entity.getName();
    }
}

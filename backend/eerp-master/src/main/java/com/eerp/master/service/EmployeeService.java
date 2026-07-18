package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.SysEmployee;
import com.eerp.master.mapper.SysEmployeeMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 员工主数据服务（平铺，bo_code=MD_EMPLOYEE，表 sys_employee）。
 */
@Service
public class EmployeeService extends AbstractMasterDataService<SysEmployee> {

    @Autowired
    private SysEmployeeMapper sysEmployeeMapper;

    @Override
    protected String boCode() {
        return "MD_EMPLOYEE";
    }

    @Override
    protected BaseMapper<SysEmployee> mapper() {
        return sysEmployeeMapper;
    }
}

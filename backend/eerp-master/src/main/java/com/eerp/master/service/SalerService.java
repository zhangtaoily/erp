package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.SysSaler;
import com.eerp.master.mapper.SysSalerMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 销售员主数据服务（平铺，bo_code=MD_SALER，表 sys_saler）。
 */
@Service
public class SalerService extends AbstractMasterDataService<SysSaler> {

    @Autowired
    private SysSalerMapper sysSalerMapper;

    @Override
    protected String boCode() {
        return "MD_SALER";
    }

    @Override
    protected BaseMapper<SysSaler> mapper() {
        return sysSalerMapper;
    }
}

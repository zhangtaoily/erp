package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdWarehouse;
import com.eerp.master.mapper.MdWarehouseMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 仓库主数据服务（平铺，bo_code=MD_WAREHOUSE，表 md_warehouse）。
 */
@Service
public class WarehouseService extends AbstractMasterDataService<MdWarehouse> {

    @Autowired
    private MdWarehouseMapper mdWarehouseMapper;

    @Override
    protected String boCode() {
        return "MD_WAREHOUSE";
    }

    @Override
    protected BaseMapper<MdWarehouse> mapper() {
        return mdWarehouseMapper;
    }
}

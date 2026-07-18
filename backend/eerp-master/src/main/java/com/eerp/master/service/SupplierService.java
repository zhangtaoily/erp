package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdSupplier;
import com.eerp.master.mapper.MdSupplierMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SupplierService extends AbstractMasterDataService<MdSupplier> {

    @Autowired
    private MdSupplierMapper mdSupplierMapper;

    @Override
    protected String boCode() {
        return "MD_SUPPLIER";
    }

    @Override
    protected BaseMapper<MdSupplier> mapper() {
        return mdSupplierMapper;
    }
}

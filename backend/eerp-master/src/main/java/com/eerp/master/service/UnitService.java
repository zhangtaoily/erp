package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdUnit;
import com.eerp.master.mapper.MdUnitMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UnitService extends AbstractMasterDataService<MdUnit> {

    @Autowired
    private MdUnitMapper mdUnitMapper;

    @Override
    protected String boCode() {
        return "MD_UNIT";
    }

    @Override
    protected BaseMapper<MdUnit> mapper() {
        return mdUnitMapper;
    }
}

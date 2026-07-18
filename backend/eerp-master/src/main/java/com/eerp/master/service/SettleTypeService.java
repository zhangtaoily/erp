package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdFirpType;
import com.eerp.master.mapper.MdFirpTypeMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SettleTypeService extends AbstractMasterDataService<MdFirpType> {

    @Autowired
    private MdFirpTypeMapper mdFirpTypeMapper;

    @Override
    protected String boCode() {
        return "MD_SETTLE_TYPE";
    }

    @Override
    protected BaseMapper<MdFirpType> mapper() {
        return mdFirpTypeMapper;
    }
}

package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdSeal;
import com.eerp.master.mapper.MdSealMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SealService extends AbstractMasterDataService<MdSeal> {

    @Autowired
    private MdSealMapper mdSealMapper;

    @Override
    protected String boCode() {
        return "MD_SEAL";
    }

    @Override
    protected BaseMapper<MdSeal> mapper() {
        return mdSealMapper;
    }
}

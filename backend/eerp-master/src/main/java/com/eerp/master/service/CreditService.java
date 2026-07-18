package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdCredit;
import com.eerp.master.mapper.MdCreditMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CreditService extends AbstractMasterDataService<MdCredit> {

    @Autowired
    private MdCreditMapper mdCreditMapper;

    @Override
    protected String boCode() {
        return "MD_CREDIT";
    }

    @Override
    protected BaseMapper<MdCredit> mapper() {
        return mdCreditMapper;
    }
}

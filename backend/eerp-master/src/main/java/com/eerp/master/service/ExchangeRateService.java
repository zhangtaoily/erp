package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdExchangeRate;
import com.eerp.master.mapper.MdExchangeRateMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ExchangeRateService extends AbstractMasterDataService<MdExchangeRate> {

    @Autowired
    private MdExchangeRateMapper mdExchangeRateMapper;

    @Override
    protected String boCode() {
        return "MD_EXCHANGE_RATE";
    }

    @Override
    protected BaseMapper<MdExchangeRate> mapper() {
        return mdExchangeRateMapper;
    }
}

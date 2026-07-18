package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdCurrency;
import com.eerp.master.mapper.MdCurrencyMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 币种主数据服务（平铺，bo_code=MD_CURRENCY，表 md_currency）。
 */
@Service
public class CurrencyService extends AbstractMasterDataService<MdCurrency> {

    @Autowired
    private MdCurrencyMapper mdCurrencyMapper;

    @Override
    protected String boCode() {
        return "MD_CURRENCY";
    }

    @Override
    protected BaseMapper<MdCurrency> mapper() {
        return mdCurrencyMapper;
    }
}

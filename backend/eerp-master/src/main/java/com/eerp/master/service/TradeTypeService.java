package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdTradeType;
import com.eerp.master.mapper.MdTradeTypeMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class TradeTypeService extends AbstractMasterDataService<MdTradeType> {

    @Autowired
    private MdTradeTypeMapper mdTradeTypeMapper;

    @Override
    protected String boCode() {
        return "MD_TRADE_TYPE";
    }

    @Override
    protected BaseMapper<MdTradeType> mapper() {
        return mdTradeTypeMapper;
    }
}

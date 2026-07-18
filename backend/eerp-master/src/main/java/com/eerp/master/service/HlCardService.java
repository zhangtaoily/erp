package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdHlCard;
import com.eerp.master.mapper.MdHlCardMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class HlCardService extends AbstractMasterDataService<MdHlCard> {

    @Autowired
    private MdHlCardMapper mdHlCardMapper;

    @Override
    protected String boCode() {
        return "MD_HL_CARD";
    }

    @Override
    protected BaseMapper<MdHlCard> mapper() {
        return mdHlCardMapper;
    }
}

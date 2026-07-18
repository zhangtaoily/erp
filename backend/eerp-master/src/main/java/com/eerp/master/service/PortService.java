package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdHarbour;
import com.eerp.master.mapper.MdHarbourMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PortService extends AbstractMasterDataService<MdHarbour> {

    @Autowired
    private MdHarbourMapper mdHarbourMapper;

    @Override
    protected String boCode() {
        return "MD_PORT";
    }

    @Override
    protected BaseMapper<MdHarbour> mapper() {
        return mdHarbourMapper;
    }
}

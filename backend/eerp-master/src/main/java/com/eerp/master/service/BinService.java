package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdPosition;
import com.eerp.master.mapper.MdPositionMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class BinService extends AbstractMasterDataService<MdPosition> {

    @Autowired
    private MdPositionMapper mdPositionMapper;

    @Override
    protected String boCode() {
        return "MD_BIN";
    }

    @Override
    protected BaseMapper<MdPosition> mapper() {
        return mdPositionMapper;
    }
}

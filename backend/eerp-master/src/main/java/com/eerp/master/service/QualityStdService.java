package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdQualityStd;
import com.eerp.master.mapper.MdQualityStdMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class QualityStdService extends AbstractMasterDataService<MdQualityStd> {

    @Autowired
    private MdQualityStdMapper mdQualityStdMapper;

    @Override
    protected String boCode() {
        return "MD_QUALITY_STD";
    }

    @Override
    protected BaseMapper<MdQualityStd> mapper() {
        return mdQualityStdMapper;
    }
}

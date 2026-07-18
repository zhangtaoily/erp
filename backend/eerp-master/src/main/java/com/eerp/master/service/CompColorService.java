package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdCompColor;
import com.eerp.master.mapper.MdCompColorMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CompColorService extends AbstractMasterDataService<MdCompColor> {

    @Autowired
    private MdCompColorMapper mdCompColorMapper;

    @Override
    protected String boCode() {
        return "MD_COMP_COLOR";
    }

    @Override
    protected BaseMapper<MdCompColor> mapper() {
        return mdCompColorMapper;
    }
}

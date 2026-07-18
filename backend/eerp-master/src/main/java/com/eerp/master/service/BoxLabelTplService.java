package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdBoxLabelTpl;
import com.eerp.master.mapper.MdBoxLabelTplMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class BoxLabelTplService extends AbstractMasterDataService<MdBoxLabelTpl> {

    @Autowired
    private MdBoxLabelTplMapper mdBoxLabelTplMapper;

    @Override
    protected String boCode() {
        return "MD_BOX_LABEL_TPL";
    }

    @Override
    protected BaseMapper<MdBoxLabelTpl> mapper() {
        return mdBoxLabelTplMapper;
    }
}

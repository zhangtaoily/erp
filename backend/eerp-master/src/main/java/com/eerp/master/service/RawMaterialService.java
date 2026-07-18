package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdRawMaterial;
import com.eerp.master.mapper.MdRawMaterialMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RawMaterialService extends AbstractMasterDataService<MdRawMaterial> {

    @Autowired
    private MdRawMaterialMapper mdRawMaterialMapper;

    @Override
    protected String boCode() {
        return "MD_RAW_MATERIAL";
    }

    @Override
    protected BaseMapper<MdRawMaterial> mapper() {
        return mdRawMaterialMapper;
    }
}

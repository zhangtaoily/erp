package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdMaterial;
import com.eerp.master.mapper.MdMaterialMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MaterialService extends AbstractMasterDataService<MdMaterial> {

    @Autowired
    private MdMaterialMapper mdMaterialMapper;

    @Override
    protected String boCode() {
        return "MD_MATERIAL";
    }

    @Override
    protected BaseMapper<MdMaterial> mapper() {
        return mdMaterialMapper;
    }
}

package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdMaterialGroup;
import com.eerp.master.mapper.MdMaterialGroupMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MaterialGroupService extends AbstractTreeMasterDataService<MdMaterialGroup> {

    @Autowired
    private MdMaterialGroupMapper mdMaterialGroupMapper;

    @Override
    protected String boCode() {
        return "MD_MATERIAL_GROUP";
    }

    @Override
    protected BaseMapper<MdMaterialGroup> mapper() {
        return mdMaterialGroupMapper;
    }

    @Override
    protected String tableName() {
        return "md_material_group";
    }

    @Override
    protected Long getParentId(MdMaterialGroup entity) {
        return entity.getParentId();
    }

    @Override
    protected Long getId(MdMaterialGroup entity) {
        return entity.getId();
    }

    @Override
    protected String getName(MdMaterialGroup entity) {
        return entity.getCnName();
    }
}

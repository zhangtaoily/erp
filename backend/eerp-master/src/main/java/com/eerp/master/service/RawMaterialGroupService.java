package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdRawMaterialGroup;
import com.eerp.master.mapper.MdRawMaterialGroupMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RawMaterialGroupService extends AbstractTreeMasterDataService<MdRawMaterialGroup> {

    @Autowired
    private MdRawMaterialGroupMapper mdRawMaterialGroupMapper;

    @Override
    protected String boCode() {
        return "MD_RAW_MATERIAL_GROUP";
    }

    @Override
    protected BaseMapper<MdRawMaterialGroup> mapper() {
        return mdRawMaterialGroupMapper;
    }

    @Override
    protected String tableName() {
        return "md_raw_material_group";
    }

    @Override
    protected Long getParentId(MdRawMaterialGroup entity) {
        return entity.getParentId();
    }

    @Override
    protected Long getId(MdRawMaterialGroup entity) {
        return entity.getId();
    }

    @Override
    protected String getName(MdRawMaterialGroup entity) {
        return entity.getCnName();
    }
}

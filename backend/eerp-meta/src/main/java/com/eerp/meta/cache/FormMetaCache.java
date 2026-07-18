package com.eerp.meta.cache;

import com.eerp.common.cache.AbstractMetaCache;
import com.eerp.meta.bo.entity.MetaBusinessObject;
import com.eerp.meta.bo.service.MetaBusinessObjectService;
import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.entity.dto.FormEntityDTO;
import com.eerp.meta.entity.entity.MetaFormEntity;
import com.eerp.meta.field.entity.MetaFormField;
import com.eerp.meta.field.service.MetaFormFieldService;
import com.eerp.meta.entity.service.MetaFormEntityService;
import com.eerp.meta.layout.entity.MetaFormLayout;
import com.eerp.meta.layout.service.MetaFormLayoutService;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * 表单元数据缓存（按 boCode 聚合：业务对象 + 实体含字段 + 默认布局）
 */
@Component
public class FormMetaCache extends AbstractMetaCache<String, FormMetaVO> {

    @Autowired
    private MetaBusinessObjectService businessObjectService;

    @Autowired
    private MetaFormEntityService formEntityService;

    @Autowired
    private MetaFormFieldService formFieldService;

    @Autowired
    private MetaFormLayoutService formLayoutService;

    @Override
    protected FormMetaVO load(String boCode) {
        MetaBusinessObject bo = businessObjectService.getByBoCode(boCode);
        if (bo == null) {
            return null;
        }
        FormMetaVO vo = new FormMetaVO();
        vo.setBusinessObject(bo);

        // 组装实体列表（每个实体含字段）
        List<MetaFormEntity> entities = formEntityService.listByBoCode(boCode);
        List<FormEntityDTO> entityDTOs = new ArrayList<>(entities.size());
        for (MetaFormEntity entity : entities) {
            FormEntityDTO dto = new FormEntityDTO();
            BeanUtils.copyProperties(entity, dto);
            List<MetaFormField> fields = formFieldService.listByBoAndEntity(boCode, entity.getEntityCode());
            dto.setFields(fields);
            entityDTOs.add(dto);
        }
        vo.setEntities(entityDTOs);

        // 默认布局
        MetaFormLayout layout = formLayoutService.getDefault(boCode);
        vo.setLayout(layout);
        return vo;
    }
}

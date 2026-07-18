package com.eerp.api.sys.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.eerp.api.sys.entity.SysDept;
import com.eerp.api.sys.mapper.SysDeptMapper;
import com.eerp.api.sys.service.SysDeptService;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;

@Service
public class SysDeptServiceImpl extends ServiceImpl<SysDeptMapper, SysDept> implements SysDeptService {

    @Override
    public List<SysDept> list(Map<String, Object> params) {
        LambdaQueryWrapper<SysDept> wrapper = new LambdaQueryWrapper<>();
        if (params != null) {
            Object orgId = params.get("orgId");
            if (orgId != null && StringUtils.hasText(orgId.toString())) {
                wrapper.eq(SysDept::getOrgId, orgId);
            }
            Object name = params.get("name");
            if (name != null && StringUtils.hasText(name.toString())) {
                wrapper.like(SysDept::getName, name);
            }
        }
        wrapper.orderByAsc(SysDept::getOrgId).orderByAsc(SysDept::getSortIndex);
        return list(wrapper);
    }
}

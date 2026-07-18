package com.eerp.api.sys.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.eerp.api.sys.entity.SysOrg;
import com.eerp.api.sys.mapper.SysOrgMapper;
import com.eerp.api.sys.service.SysOrgService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class SysOrgServiceImpl extends ServiceImpl<SysOrgMapper, SysOrg> implements SysOrgService {

    @Override
    public List<SysOrg> tree() {
        LambdaQueryWrapper<SysOrg> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByAsc(SysOrg::getParentId).orderByAsc(SysOrg::getSortIndex);
        return list(wrapper);
    }
}

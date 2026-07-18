package com.eerp.api.sys.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.eerp.api.sys.entity.SysUser;
import com.eerp.api.sys.mapper.SysUserMapper;
import com.eerp.api.sys.service.SysUserService;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;

@Service
public class SysUserServiceImpl extends ServiceImpl<SysUserMapper, SysUser> implements SysUserService {

    @Override
    public SysUser getByUsername(String username) {
        LambdaQueryWrapper<SysUser> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SysUser::getUsername, username);
        return getOne(wrapper);
    }

    @Override
    public List<SysUser> list(Map<String, Object> params) {
        LambdaQueryWrapper<SysUser> wrapper = new LambdaQueryWrapper<>();
        if (params != null) {
            Object username = params.get("username");
            if (username != null && StringUtils.hasText(username.toString())) {
                wrapper.like(SysUser::getUsername, username);
            }
            Object realName = params.get("realName");
            if (realName != null && StringUtils.hasText(realName.toString())) {
                wrapper.like(SysUser::getRealName, realName);
            }
            Object orgId = params.get("orgId");
            if (orgId != null && StringUtils.hasText(orgId.toString())) {
                wrapper.eq(SysUser::getOrgId, orgId);
            }
            Object status = params.get("status");
            if (status != null && StringUtils.hasText(status.toString())) {
                wrapper.eq(SysUser::getStatus, status);
            }
        }
        wrapper.orderByDesc(SysUser::getCreateTime);
        return list(wrapper);
    }
}

package com.eerp.api.sys.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.eerp.api.sys.entity.SysRole;
import com.eerp.api.sys.entity.SysRoleButton;
import com.eerp.api.sys.mapper.SysRoleButtonMapper;
import com.eerp.api.sys.mapper.SysRoleMapper;
import com.eerp.api.sys.service.SysRoleService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class SysRoleServiceImpl extends ServiceImpl<SysRoleMapper, SysRole> implements SysRoleService {

    private final SysRoleButtonMapper roleButtonMapper;

    public SysRoleServiceImpl(SysRoleButtonMapper roleButtonMapper) {
        this.roleButtonMapper = roleButtonMapper;
    }

    @Override
    public List<SysRole> list() {
        LambdaQueryWrapper<SysRole> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByAsc(SysRole::getParentId);
        return list(wrapper);
    }

    @Override
    public List<SysRoleButton> listButtons(Long roleId) {
        LambdaQueryWrapper<SysRoleButton> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SysRoleButton::getRoleId, roleId);
        return roleButtonMapper.selectList(wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveButtons(Long roleId, List<SysRoleButton> buttons) {
        LambdaQueryWrapper<SysRoleButton> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SysRoleButton::getRoleId, roleId);
        roleButtonMapper.delete(wrapper);
        if (buttons != null) {
            for (SysRoleButton button : buttons) {
                button.setRoleId(roleId);
                if (button.getId() == null) {
                    roleButtonMapper.insert(button);
                } else {
                    roleButtonMapper.updateById(button);
                }
            }
        }
    }
}

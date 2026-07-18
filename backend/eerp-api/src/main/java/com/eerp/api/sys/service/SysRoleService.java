package com.eerp.api.sys.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.api.sys.entity.SysRole;
import com.eerp.api.sys.entity.SysRoleButton;

import java.util.List;

public interface SysRoleService extends IService<SysRole> {

    List<SysRole> list();

    List<SysRoleButton> listButtons(Long roleId);

    void saveButtons(Long roleId, List<SysRoleButton> buttons);
}

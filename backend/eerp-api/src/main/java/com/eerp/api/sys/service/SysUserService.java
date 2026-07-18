package com.eerp.api.sys.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.api.sys.entity.SysUser;

import java.util.List;
import java.util.Map;

public interface SysUserService extends IService<SysUser> {

    SysUser getByUsername(String username);

    List<SysUser> list(Map<String, Object> params);
}

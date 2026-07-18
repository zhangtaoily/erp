package com.eerp.api.sys.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.api.sys.entity.SysMenu;

import java.util.List;

/**
 * 系统菜单 Service
 */
public interface SysMenuService extends IService<SysMenu> {

    /**
     * 查询所有启用的菜单（按 sort_index 升序），用于侧边栏渲染
     */
    List<SysMenu> listAllEnabled();

    /**
     * 查询全部菜单（含停用，管理后台用），返回树形结构
     */
    List<SysMenu> listTree();

    /**
     * 新增菜单
     */
    SysMenu create(SysMenu menu);

    /**
     * 更新菜单
     */
    SysMenu update(Long id, SysMenu menu);

    /**
     * 删除菜单（含子菜单级联删除）
     */
    void delete(Long id);
}

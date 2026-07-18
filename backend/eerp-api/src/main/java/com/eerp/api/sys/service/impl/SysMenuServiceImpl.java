package com.eerp.api.sys.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.eerp.api.sys.entity.SysMenu;
import com.eerp.api.sys.mapper.SysMenuMapper;
import com.eerp.api.sys.service.SysMenuService;
import com.eerp.common.exception.ServiceException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 系统菜单 Service 实现
 */
@Service
public class SysMenuServiceImpl extends ServiceImpl<SysMenuMapper, SysMenu> implements SysMenuService {

    @Override
    public List<SysMenu> listAllEnabled() {
        LambdaQueryWrapper<SysMenu> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SysMenu::getStatus, 1)
                .eq(SysMenu::getVisible, 1)
                .orderByAsc(SysMenu::getSortIndex);
        List<SysMenu> flat = list(wrapper);
        return buildTree(flat);
    }

    @Override
    public List<SysMenu> listTree() {
        LambdaQueryWrapper<SysMenu> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByAsc(SysMenu::getSortIndex);
        List<SysMenu> flat = list(wrapper);
        return buildTree(flat);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public SysMenu create(SysMenu menu) {
        if (menu.getParentId() == null) {
            menu.setParentId(0L);
        }
        if (menu.getSortIndex() == null) {
            menu.setSortIndex(99);
        }
        if (menu.getStatus() == null) {
            menu.setStatus(1);
        }
        if (menu.getVisible() == null) {
            menu.setVisible(1);
        }
        save(menu);
        return menu;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public SysMenu update(Long id, SysMenu menu) {
        menu.setId(id);
        updateById(menu);
        return menu;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        // 检查是否有子菜单
        LambdaQueryWrapper<SysMenu> childWrapper = new LambdaQueryWrapper<>();
        childWrapper.eq(SysMenu::getParentId, id);
        long childCount = count(childWrapper);
        if (childCount > 0) {
            throw new RuntimeException("该菜单下有子菜单，请先删除子菜单");
        }
        removeById(id);
    }

    /**
     * 构建菜单树（parentId=0 或 null 为根）
     */
    private List<SysMenu> buildTree(List<SysMenu> flat) {
        Map<Long, List<SysMenu>> byParent = flat.stream()
                .collect(Collectors.groupingBy(m -> m.getParentId() == null ? 0L : m.getParentId()));
        List<SysMenu> roots = byParent.getOrDefault(0L, new ArrayList<>());
        for (SysMenu root : roots) {
            fillChildren(root, byParent);
        }
        return roots;
    }

    private void fillChildren(SysMenu parent, Map<Long, List<SysMenu>> byParent) {
        List<SysMenu> children = byParent.get(parent.getId());
        if (children != null && !children.isEmpty()) {
            parent.setChildren(children);
            for (SysMenu child : children) {
                fillChildren(child, byParent);
            }
        }
    }
}

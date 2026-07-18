package com.eerp.api.sys;

import com.eerp.api.sys.entity.SysMenu;
import com.eerp.api.sys.service.SysMenuService;
import com.eerp.common.api.Result;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 系统菜单接口
 * <p>前端启动时调用 /api/menu/tree 加载侧边栏菜单（仅启用且可见）；
 * 管理后台通过 /api/menu/admin/tree 获取全部菜单（含停用）进行 CRUD。</p>
 */
@RestController
public class MenuController {

    private final SysMenuService menuService;

    public MenuController(SysMenuService menuService) {
        this.menuService = menuService;
    }

    /**
     * 侧边栏渲染用：仅返回启用且可见的菜单树
     */
    @GetMapping("/api/menu/tree")
    public Result<List<SysMenu>> tree() {
        return Result.ok(menuService.listAllEnabled());
    }

    /**
     * 管理后台用：返回全部菜单树（含停用）
     */
    @GetMapping("/api/menu/admin/tree")
    public Result<List<SysMenu>> adminTree() {
        return Result.ok(menuService.listTree());
    }

    @PostMapping("/api/menu")
    public Result<SysMenu> create(@RequestBody SysMenu data) {
        return Result.ok(menuService.create(data));
    }

    @PutMapping("/api/menu/{id}")
    public Result<SysMenu> update(@PathVariable Long id, @RequestBody SysMenu data) {
        return Result.ok(menuService.update(id, data));
    }

    @DeleteMapping("/api/menu/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        menuService.delete(id);
        return Result.ok();
    }
}

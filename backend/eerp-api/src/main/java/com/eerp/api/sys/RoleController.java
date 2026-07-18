package com.eerp.api.sys;

import com.eerp.api.sys.entity.SysRole;
import com.eerp.api.sys.entity.SysRoleButton;
import com.eerp.api.sys.service.SysRoleService;
import com.eerp.common.api.Result;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
public class RoleController {

    private final SysRoleService roleService;
    private final JdbcTemplate jdbcTemplate;

    public RoleController(SysRoleService roleService, JdbcTemplate jdbcTemplate) {
        this.roleService = roleService;
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/api/role/list")
    public Result<List<SysRole>> list() {
        return Result.ok(roleService.list());
    }

    @PostMapping("/api/role")
    public Result<SysRole> create(@RequestBody SysRole data) {
        roleService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/api/role/{id}")
    public Result<SysRole> update(@PathVariable Long id, @RequestBody SysRole data) {
        data.setId(id);
        roleService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/api/role/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        roleService.removeById(id);
        return Result.ok();
    }

    @GetMapping("/api/role/{roleId}/buttons")
    public Result<List<SysRoleButton>> buttons(@PathVariable Long roleId) {
        return Result.ok(roleService.listButtons(roleId));
    }

    @PutMapping("/api/role/{roleId}/buttons")
    public Result<Void> saveButtons(@PathVariable Long roleId, @RequestBody Map<String, Object> body) {
        Object buttonsObj = body.get("buttons");
        List<SysRoleButton> buttons = new java.util.ArrayList<>();
        if (buttonsObj instanceof List) {
            for (Object item : (List<?>) buttonsObj) {
                SysRoleButton button = convertButton(item, roleId);
                buttons.add(button);
            }
        }
        roleService.saveButtons(roleId, buttons);
        return Result.ok();
    }

    @GetMapping("/api/bo/{boCode}/role-buttons")
    public Result<List<Map<String, Object>>> buttonsByBo(@PathVariable String boCode) {
        List<Map<String, Object>> result = jdbcTemplate.queryForList(
                "SELECT rb.*, r.role_name FROM sys_role_button rb " +
                        "LEFT JOIN sys_role r ON rb.role_id = r.id " +
                        "WHERE rb.bo_code = ?", boCode);
        return Result.ok(result);
    }

    @SuppressWarnings("unchecked")
    private SysRoleButton convertButton(Object item, Long roleId) {
        if (item instanceof SysRoleButton) {
            SysRoleButton b = (SysRoleButton) item;
            b.setRoleId(roleId);
            return b;
        }
        Map<String, Object> map = (Map<String, Object>) item;
        SysRoleButton button = new SysRoleButton();
        button.setRoleId(roleId);
        button.setBoCode((String) map.get("boCode"));
        button.setButtonCode((String) map.get("buttonCode"));
        button.setControlLevel((String) map.get("controlLevel"));
        return button;
    }
}

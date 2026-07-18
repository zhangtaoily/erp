package com.eerp.api.sys;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.api.sys.entity.SysUser;
import com.eerp.api.sys.entity.SysUserOrg;
import com.eerp.api.sys.mapper.SysUserOrgMapper;
import com.eerp.api.sys.service.SysUserService;
import com.eerp.common.api.Result;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/user")
public class UserController {

    private final SysUserService userService;
    private final SysUserOrgMapper userOrgMapper;
    private final PasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper;

    public UserController(SysUserService userService,
                          SysUserOrgMapper userOrgMapper,
                          PasswordEncoder passwordEncoder,
                          ObjectMapper objectMapper) {
        this.userService = userService;
        this.userOrgMapper = userOrgMapper;
        this.passwordEncoder = passwordEncoder;
        this.objectMapper = objectMapper;
    }

    @GetMapping("/list")
    public Result<List<SysUser>> list(@RequestParam(required = false) Map<String, Object> params) {
        return Result.ok(userService.list(params));
    }

    @PostMapping
    public Result<SysUser> create(@RequestBody Map<String, Object> body) {
        SysUser user = objectMapper.convertValue(body, SysUser.class);
        Object password = body.get("password");
        if (password != null && !password.toString().isEmpty()) {
            user.setPassword(passwordEncoder.encode(password.toString()));
        }
        userService.save(user);
        return Result.ok(user);
    }

    @PutMapping("/{id}")
    public Result<SysUser> update(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        SysUser user = objectMapper.convertValue(body, SysUser.class);
        user.setId(id);
        Object password = body.get("password");
        if (password != null && !password.toString().isEmpty()) {
            user.setPassword(passwordEncoder.encode(password.toString()));
        }
        userService.updateById(user);
        return Result.ok(user);
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        userService.removeById(id);
        return Result.ok();
    }

    @GetMapping("/{userId}/orgs")
    public Result<List<SysUserOrg>> userOrgs(@PathVariable Long userId) {
        LambdaQueryWrapper<SysUserOrg> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SysUserOrg::getUserId, userId);
        return Result.ok(userOrgMapper.selectList(wrapper));
    }

    @PutMapping("/{userId}/orgs")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> saveUserOrgs(@PathVariable Long userId, @RequestBody Map<String, Object> body) {
        LambdaQueryWrapper<SysUserOrg> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SysUserOrg::getUserId, userId);
        userOrgMapper.delete(wrapper);

        Object orgsObj = body.get("orgs");
        if (orgsObj instanceof List) {
            for (Object item : (List<?>) orgsObj) {
                SysUserOrg userOrg = objectMapper.convertValue(item, SysUserOrg.class);
                userOrg.setId(null);
                userOrg.setUserId(userId);
                userOrgMapper.insert(userOrg);
            }
        }
        return Result.ok();
    }
}

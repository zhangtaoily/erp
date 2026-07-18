package com.eerp.api.sys;

import com.eerp.api.sys.entity.SysOrg;
import com.eerp.api.sys.service.SysOrgService;
import com.eerp.common.api.Result;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/org")
public class OrgController {

    private final SysOrgService orgService;

    public OrgController(SysOrgService orgService) {
        this.orgService = orgService;
    }

    @GetMapping("/tree")
    public Result<List<SysOrg>> tree() {
        return Result.ok(orgService.tree());
    }

    @PostMapping
    public Result<SysOrg> create(@RequestBody SysOrg data) {
        orgService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/{id}")
    public Result<SysOrg> update(@PathVariable Long id, @RequestBody SysOrg data) {
        data.setId(id);
        orgService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        orgService.removeById(id);
        return Result.ok();
    }
}

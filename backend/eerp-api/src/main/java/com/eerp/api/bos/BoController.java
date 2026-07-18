package com.eerp.api.bos;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;
import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.meta.bo.entity.MetaBusinessObject;
import com.eerp.meta.bo.service.MetaBusinessObjectService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bo")
public class BoController {

    private final MetaBusinessObjectService businessObjectService;

    public BoController(MetaBusinessObjectService businessObjectService) {
        this.businessObjectService = businessObjectService;
    }

    @GetMapping("/list")
    public Result<PageResult<MetaBusinessObject>> list(PageRequest pageRequest,
                                                       @RequestParam(required = false) String boName,
                                                       @RequestParam(required = false) String boType) {
        Page<MetaBusinessObject> page = new Page<>(pageRequest.getPageNum(), pageRequest.getPageSize());
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MetaBusinessObject> wrapper =
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        if (boName != null && !boName.isEmpty()) {
            wrapper.like(MetaBusinessObject::getBoName, boName);
        }
        if (boType != null && !boType.isEmpty()) {
            wrapper.eq(MetaBusinessObject::getBoType, boType);
        }
        wrapper.orderByDesc(MetaBusinessObject::getCreateTime);
        Page<MetaBusinessObject> result = businessObjectService.page(page, wrapper);
        PageResult<MetaBusinessObject> pageResult = new PageResult<>(
                result.getRecords(), result.getTotal(),
                (int) result.getCurrent(), (int) result.getSize());
        return Result.ok(pageResult);
    }

    @GetMapping("/{boCode}")
    public Result<MetaBusinessObject> detail(@PathVariable String boCode) {
        MetaBusinessObject bo = businessObjectService.getByBoCode(boCode);
        if (bo == null) {
            throw new ServiceException("BO_001", "业务对象不存在: " + boCode);
        }
        return Result.ok(bo);
    }

    @PostMapping
    public Result<MetaBusinessObject> create(@RequestBody MetaBusinessObject data) {
        businessObjectService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/{boCode}")
    public Result<MetaBusinessObject> update(@PathVariable String boCode, @RequestBody MetaBusinessObject data) {
        MetaBusinessObject existing = businessObjectService.getByBoCode(boCode);
        if (existing == null) {
            throw new ServiceException("BO_001", "业务对象不存在: " + boCode);
        }
        data.setId(existing.getId());
        data.setBoCode(boCode);
        businessObjectService.updateById(data);
        return Result.ok(data);
    }

    @PutMapping("/{boCode}/status")
    public Result<Void> toggleStatus(@PathVariable String boCode, @RequestBody java.util.Map<String, Object> body) {
        MetaBusinessObject existing = businessObjectService.getByBoCode(boCode);
        if (existing == null) {
            throw new ServiceException("BO_001", "业务对象不存在: " + boCode);
        }
        Object status = body.get("status");
        if (status != null) {
            existing.setStatus(Integer.parseInt(status.toString()));
            businessObjectService.updateById(existing);
        }
        return Result.ok();
    }
}

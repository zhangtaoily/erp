package com.eerp.api.bos;

import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.meta.entity.dto.FormEntityDTO;
import com.eerp.meta.entity.entity.MetaFormEntity;
import com.eerp.meta.entity.service.MetaFormEntityService;
import com.eerp.meta.field.entity.MetaFormField;
import com.eerp.meta.field.service.MetaFormFieldService;
import org.springframework.beans.BeanUtils;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api")
public class EntityController {

    private final MetaFormEntityService formEntityService;
    private final MetaFormFieldService formFieldService;

    public EntityController(MetaFormEntityService formEntityService, MetaFormFieldService formFieldService) {
        this.formEntityService = formEntityService;
        this.formFieldService = formFieldService;
    }

    @GetMapping("/bo/{boCode}/entities")
    public Result<List<FormEntityDTO>> list(@PathVariable String boCode) {
        List<MetaFormEntity> entities = formEntityService.listByBoCode(boCode);
        List<FormEntityDTO> result = new ArrayList<>(entities.size());
        for (MetaFormEntity entity : entities) {
            FormEntityDTO dto = new FormEntityDTO();
            BeanUtils.copyProperties(entity, dto);
            List<MetaFormField> fields = formFieldService.listByEntityCode(entity.getEntityCode());
            dto.setFields(fields);
            result.add(dto);
        }
        return Result.ok(result);
    }

    @PostMapping("/entity")
    public Result<MetaFormEntity> create(@RequestBody MetaFormEntity data) {
        formEntityService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/entity/{id}")
    public Result<MetaFormEntity> update(@PathVariable Long id, @RequestBody MetaFormEntity data) {
        data.setId(id);
        formEntityService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/entity/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        formEntityService.removeById(id);
        return Result.ok();
    }
}

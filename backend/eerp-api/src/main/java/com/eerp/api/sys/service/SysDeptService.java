package com.eerp.api.sys.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.api.sys.entity.SysDept;

import java.util.List;
import java.util.Map;

public interface SysDeptService extends IService<SysDept> {

    List<SysDept> list(Map<String, Object> params);
}

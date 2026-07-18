package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.SysDict;
import com.eerp.master.mapper.SysDictMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class DataDictionaryService extends AbstractMasterDataService<SysDict> {

    @Autowired
    private SysDictMapper sysDictMapper;

    @Override
    protected String boCode() {
        return "SYS_DICT";
    }

    @Override
    protected BaseMapper<SysDict> mapper() {
        return sysDictMapper;
    }
}

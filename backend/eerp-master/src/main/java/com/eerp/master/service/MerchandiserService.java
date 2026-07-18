package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.SysMerchandiser;
import com.eerp.master.mapper.SysMerchandiserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 跟单员主数据服务（平铺，bo_code=MD_MERCHANDISER，表 sys_merchandiser）。
 */
@Service
public class MerchandiserService extends AbstractMasterDataService<SysMerchandiser> {

    @Autowired
    private SysMerchandiserMapper sysMerchandiserMapper;

    @Override
    protected String boCode() {
        return "MD_MERCHANDISER";
    }

    @Override
    protected BaseMapper<SysMerchandiser> mapper() {
        return sysMerchandiserMapper;
    }
}

package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdBrand;
import com.eerp.master.mapper.MdBrandMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class BrandService extends AbstractMasterDataService<MdBrand> {

    @Autowired
    private MdBrandMapper mdBrandMapper;

    @Override
    protected String boCode() {
        return "MD_BRAND";
    }

    @Override
    protected BaseMapper<MdBrand> mapper() {
        return mdBrandMapper;
    }
}

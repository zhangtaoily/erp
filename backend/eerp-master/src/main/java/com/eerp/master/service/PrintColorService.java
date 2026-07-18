package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdPrintColor;
import com.eerp.master.mapper.MdPrintColorMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PrintColorService extends AbstractMasterDataService<MdPrintColor> {

    @Autowired
    private MdPrintColorMapper mdPrintColorMapper;

    @Override
    protected String boCode() {
        return "MD_PRINT_COLOR";
    }

    @Override
    protected BaseMapper<MdPrintColor> mapper() {
        return mdPrintColorMapper;
    }
}

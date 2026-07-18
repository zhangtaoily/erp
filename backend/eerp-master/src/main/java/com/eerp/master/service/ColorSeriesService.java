package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdColorSeries;
import com.eerp.master.mapper.MdColorSeriesMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ColorSeriesService extends AbstractMasterDataService<MdColorSeries> {

    @Autowired
    private MdColorSeriesMapper mdColorSeriesMapper;

    @Override
    protected String boCode() {
        return "MD_COLOR_SERIES";
    }

    @Override
    protected BaseMapper<MdColorSeries> mapper() {
        return mdColorSeriesMapper;
    }
}

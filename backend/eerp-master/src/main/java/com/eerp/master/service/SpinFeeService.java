package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdSpinFee;
import com.eerp.master.mapper.MdSpinFeeMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SpinFeeService extends AbstractMasterDataService<MdSpinFee> {

    @Autowired
    private MdSpinFeeMapper mdSpinFeeMapper;

    @Override
    protected String boCode() {
        return "MD_SPIN_FEE";
    }

    @Override
    protected BaseMapper<MdSpinFee> mapper() {
        return mdSpinFeeMapper;
    }
}

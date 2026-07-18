package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.MdCustomer;
import com.eerp.master.mapper.MdCustomerMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CustomerService extends AbstractMasterDataService<MdCustomer> {

    @Autowired
    private MdCustomerMapper mdCustomerMapper;

    @Override
    protected String boCode() {
        return "MD_CUSTOMER";
    }

    @Override
    protected BaseMapper<MdCustomer> mapper() {
        return mdCustomerMapper;
    }
}

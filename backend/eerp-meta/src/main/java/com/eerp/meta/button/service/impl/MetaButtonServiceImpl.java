package com.eerp.meta.button.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.button.entity.MetaButton;
import com.eerp.meta.button.entity.MetaFormButton;
import com.eerp.meta.button.mapper.MetaButtonMapper;
import com.eerp.meta.button.mapper.MetaFormButtonMapper;
import com.eerp.meta.button.service.MetaButtonService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 按钮 Service 实现
 */
@Service
public class MetaButtonServiceImpl
        extends AbstractCrudService<MetaButtonMapper, MetaButton>
        implements MetaButtonService {

    @Autowired
    private MetaFormButtonMapper metaFormButtonMapper;

    @Override
    public List<MetaButton> listByBoCode(String boCode) {
        // meta_button 表无 bo_code 字段，通过 meta_form_button 关联查询
        List<MetaFormButton> formButtons = metaFormButtonMapper.selectList(
                new LambdaQueryWrapper<MetaFormButton>().eq(MetaFormButton::getBoCode, boCode)
        );
        if (formButtons.isEmpty()) {
            return Collections.emptyList();
        }
        List<String> buttonCodes = formButtons.stream()
                .map(MetaFormButton::getButtonCode)
                .distinct()
                .collect(Collectors.toList());
        return lambdaQuery()
                .in(MetaButton::getButtonCode, buttonCodes)
                .orderByAsc(MetaButton::getExecOrder)
                .list();
    }

    @Override
    public List<MetaFormButton> listFormButtons(String boCode) {
        return metaFormButtonMapper.selectList(
                new LambdaQueryWrapper<MetaFormButton>()
                        .eq(MetaFormButton::getBoCode, boCode)
                        .orderByAsc(MetaFormButton::getSortIndex)
        );
    }
}

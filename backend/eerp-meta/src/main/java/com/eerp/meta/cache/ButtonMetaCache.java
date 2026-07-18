package com.eerp.meta.cache;

import com.eerp.common.cache.AbstractMetaCache;
import com.eerp.meta.button.entity.MetaButton;
import com.eerp.meta.button.entity.MetaFormButton;
import com.eerp.meta.button.service.MetaButtonService;
import com.eerp.meta.button.vo.ButtonDefVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 按钮元数据缓存（按 boCode 聚合：按钮定义 + 表单按钮绑定可用性矩阵）
 */
@Component
public class ButtonMetaCache extends AbstractMetaCache<String, List<ButtonDefVO>> {

    @Autowired
    private MetaButtonService buttonService;

    @Override
    protected List<ButtonDefVO> load(String boCode) {
        List<MetaButton> buttons = buttonService.listByBoCode(boCode);
        if (buttons.isEmpty()) {
            return new ArrayList<>();
        }
        List<MetaFormButton> formButtons = buttonService.listFormButtons(boCode);
        Map<String, MetaFormButton> formButtonMap = formButtons.stream()
                .collect(Collectors.toMap(MetaFormButton::getButtonCode, Function.identity(), (a, b) -> a));

        List<ButtonDefVO> result = new ArrayList<>(buttons.size());
        for (MetaButton button : buttons) {
            ButtonDefVO vo = new ButtonDefVO();
            vo.setId(button.getId());
            vo.setBoCode(boCode);
            vo.setButtonCode(button.getButtonCode());
            vo.setButtonName(button.getButtonName());
            vo.setIcon(button.getIcon());
            vo.setPosition(button.getLocation());
            vo.setSortIndex(button.getExecOrder());
            vo.setIsCustom("custom".equals(button.getButtonType()) ? 1 : 0);

            MetaFormButton fb = formButtonMap.get(button.getButtonCode());
            if (fb != null) {
                vo.setNeedConfirm(fb.getConfirmMsg() != null && !fb.getConfirmMsg().isEmpty() ? 1 : 0);
                vo.setConfirmMsg(fb.getConfirmMsg());
                vo.setBindPlugin(fb.getPluginEvent());
                vo.setAvailabilityJson(fb.getAvailabilityJson());
            } else {
                vo.setNeedConfirm(0);
                vo.setIsCustom(0);
            }
            result.add(vo);
        }
        return result;
    }
}

package com.eerp.api.bos;

import com.eerp.bos.button.AvailabilityMatrixResolver;
import com.eerp.bos.button.ButtonAvailability;
import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.common.security.SecurityContext;
import com.eerp.common.security.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 按钮可用性查询 Controller
 */
@RestController
@RequestMapping("/api/bos/button-availability")
public class ButtonAvailabilityController {

    private final AvailabilityMatrixResolver availabilityResolver;

    public ButtonAvailabilityController(AvailabilityMatrixResolver availabilityResolver) {
        this.availabilityResolver = availabilityResolver;
    }

    /**
     * 返回当前用户在该状态下所有按钮可用性列表
     */
    @GetMapping
    public Result<List<ButtonAvailability>> list(@RequestParam String boCode,
                                                   @RequestParam Integer pactState,
                                                   @RequestParam(required = false, defaultValue = "false") Boolean isClosed,
                                                   @RequestParam(required = false, defaultValue = "false") Boolean isCancel) {
        Long userId = currentUserId();
        List<ButtonAvailability> list = availabilityResolver.resolveAll(boCode, pactState, isClosed, isCancel, userId);
        return Result.ok(list);
    }

    /**
     * 返回单个按钮可用性
     */
    @GetMapping("/resolve")
    public Result<ButtonAvailability> resolve(@RequestParam String boCode,
                                              @RequestParam String buttonCode,
                                              @RequestParam Integer pactState,
                                              @RequestParam(required = false, defaultValue = "false") Boolean isClosed,
                                              @RequestParam(required = false, defaultValue = "false") Boolean isCancel) {
        Long userId = currentUserId();
        ButtonAvailability availability = availabilityResolver.resolve(
                boCode, buttonCode, pactState, isClosed, isCancel, userId);
        return Result.ok(availability);
    }

    private Long currentUserId() {
        SecurityContext ctx = SecurityContextHolder.get();
        if (ctx == null || ctx.getUserId() == null) {
            throw new ServiceException("AUTH_001", "未登录");
        }
        return ctx.getUserId();
    }
}

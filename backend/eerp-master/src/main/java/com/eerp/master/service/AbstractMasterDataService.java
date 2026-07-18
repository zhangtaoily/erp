package com.eerp.master.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.bos.bill.AbstractBillService;
import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;
import com.eerp.common.exception.ServiceException;
import org.springframework.beans.factory.annotation.Autowired;

import java.lang.reflect.Field;
import java.util.List;
import java.util.Map;

/**
 * 主数据 CRUD 抽象基类（对齐设计文档 06 §3.1）。
 *
 * <p>主数据（bo_type='master'）与业务单据（bo_type='bill'）的差异：</p>
 * <ul>
 *   <li>主数据多数无状态机（is_stateful=false），仅 status 字段（1启用/0停用）</li>
 *   <li>主数据 save 直接通过 {@link BillDataAccessor} 写库，不走 6 阶段流水线</li>
 *   <li>主数据 operate 仅支持 enable/disable，更新 status 字段</li>
 *   <li>主数据 getBillDetail/listBills/deleteBill 委托平台基座</li>
 * </ul>
 *
 * @param <T> 实体类型
 */
public abstract class AbstractMasterDataService<T> extends AbstractBillService {

    @Autowired
    protected BillDataAccessor billDataAccessor;

    @Autowired
    protected AbstractListService listService;

    /** 业务对象编码（子类返回，如 "MD_ORG"） */
    protected abstract String boCode();

    /** MyBatis-Plus Mapper（子类注入） */
    protected abstract BaseMapper<T> mapper();

    // ---------------- AbstractBillService 5 方法实现 ----------------

    @Override
    public BillOperationResult save(BillOperationContext ctx) {
        if (ctx.getBillData() == null) {
            return BillOperationResult.fail("主数据为空");
        }
        try {
            Long id = billDataAccessor.saveBill(boCode(), ctx.getBillData());
            afterSave(ctx, id);
            return BillOperationResult.ok(id);
        } catch (ServiceException e) {
            return BillOperationResult.fail(e.getMessage());
        }
    }

    @Override
    public BillOperationResult operate(BillOperationContext ctx) {
        Long id = ctx.getBillId();
        if (id == null) {
            return BillOperationResult.fail("主数据ID为空");
        }
        String op = ctx.getOperation();
        switch (op) {
            case "enable":
                updateStatus(id, 1);
                return BillOperationResult.ok(id);
            case "disable":
                beforeDisable(id);
                updateStatus(id, 0);
                return BillOperationResult.ok(id);
            case "delete":
                billDataAccessor.deleteBill(boCode(), id);
                return BillOperationResult.ok(id);
            default:
                return BillOperationResult.fail("不支持的操作: " + op);
        }
    }

    @Override
    public Map<String, Object> getBillDetail(String boCode, Long billId) {
        return billDataAccessor.loadBill(boCode, billId);
    }

    @Override
    public PageResult<Map<String, Object>> listBills(String boCode, PageRequest pageRequest, Map<String, Object> queryParams) {
        return listService.page(boCode, pageRequest, queryParams);
    }

    @Override
    public void deleteBill(String boCode, Long billId) {
        billDataAccessor.deleteBill(boCode, billId);
    }

    // ---------------- 主数据特有方法 ----------------

    /** 按 ID 查询实体 */
    public T findById(Long id) {
        return mapper().selectById(id);
    }

    /** 条件查询列表 */
    public List<T> list(QueryWrapper<T> wrapper) {
        return mapper().selectList(wrapper);
    }

    /** 启用 */
    public void enable(Long id) {
        updateStatus(id, 1);
    }

    /** 停用（触发引用检查钩子） */
    public void disable(Long id) {
        beforeDisable(id);
        updateStatus(id, 0);
    }

    // ---------------- 钩子方法 ----------------

    /** 保存后钩子（子类可重写，如缓存失效） */
    protected void afterSave(BillOperationContext ctx, Long id) {
    }

    /** 停用前引用检查钩子（子类可重写，被业务单据引用时阻断） */
    protected void beforeDisable(Long id) {
    }

    // ---------------- 内部工具 ----------------

    private void updateStatus(Long id, int status) {
        T entity = mapper().selectById(id);
        if (entity == null) {
            throw new ServiceException("MASTER_001", "主数据不存在: " + boCode() + "#" + id);
        }
        // 尝试 status 字段，若不存在则尝试 enabled 字段
        String fieldName = findStatusFieldName(entity.getClass());
        if (fieldName == null) {
            throw new ServiceException("MASTER_002", "主数据 " + boCode() + " 缺少 status/enabled 字段");
        }
        try {
            java.lang.reflect.Field field = entity.getClass().getDeclaredField(fieldName);
            field.setAccessible(true);
            field.set(entity, status);
            mapper().updateById(entity);
        } catch (NoSuchFieldException | IllegalAccessException e) {
            throw new ServiceException("MASTER_002", "主数据 " + boCode() + " 无法更新 " + fieldName + " 字段");
        }
    }

    /** 查找实体类中的状态字段名（status 或 enabled） */
    private String findStatusFieldName(Class<?> clazz) {
        for (Field f : clazz.getDeclaredFields()) {
            if ("status".equals(f.getName()) || "enabled".equals(f.getName())) {
                return f.getName();
            }
        }
        return null;
    }
}

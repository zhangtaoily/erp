package com.eerp.common.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.service.IService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.eerp.common.domain.BaseEntity;
import org.springframework.transaction.annotation.Transactional;

/**
 * CRUD 模板基类，基于 MyBatis-Plus 的 {@link ServiceImpl}，
 * 并提供模板方法钩子以便子类扩展保存/更新逻辑。
 */
public abstract class AbstractCrudService<M extends BaseMapper<T>, T extends BaseEntity>
        extends ServiceImpl<M, T> implements IService<T> {

    @Override
    public boolean save(T entity) {
        beforeSave(entity);
        boolean result = super.save(entity);
        afterSave(entity);
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateById(T entity) {
        beforeUpdate(entity);
        boolean result = super.updateById(entity);
        afterUpdate(entity);
        return result;
    }

    /** 保存前置钩子 */
    protected void beforeSave(T entity) {
        // 默认空实现，子类可覆盖
    }

    /** 保存后置钩子 */
    protected void afterSave(T entity) {
        // 默认空实现，子类可覆盖
    }

    /** 更新前置钩子 */
    protected void beforeUpdate(T entity) {
        // 默认空实现，子类可覆盖
    }

    /** 更新后置钩子 */
    protected void afterUpdate(T entity) {
        // 默认空实现，子类可覆盖
    }
}

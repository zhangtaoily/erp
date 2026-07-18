package com.eerp.meta.statemachine.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.statemachine.entity.MetaStateMachine;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 状态机 Mapper
 */
@Mapper
public interface MetaStateMachineMapper extends BaseMapper<MetaStateMachine> {

    @Select("SELECT * FROM meta_state_machine WHERE code = #{code} LIMIT 1")
    MetaStateMachine getByCode(@Param("code") String code);
}

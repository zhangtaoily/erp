package com.eerp.meta.statemachine.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 状态流转 Mapper
 */
@Mapper
public interface MetaStateTransitionMapper extends BaseMapper<MetaStateTransition> {

    @Select("SELECT * FROM meta_state_transition WHERE machine_id = #{machineId} ORDER BY sort_index ASC")
    List<MetaStateTransition> listByMachineId(@Param("machineId") Long machineId);
}

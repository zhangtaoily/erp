package com.eerp.meta.statemachine.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.statemachine.entity.MetaStateNode;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 状态节点 Mapper
 */
@Mapper
public interface MetaStateNodeMapper extends BaseMapper<MetaStateNode> {

    @Select("SELECT * FROM meta_state_node WHERE machine_id = #{machineId} ORDER BY sort_index ASC")
    List<MetaStateNode> listByMachineId(@Param("machineId") Long machineId);
}

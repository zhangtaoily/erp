package com.eerp.api.bos;

import com.eerp.common.api.Result;
import com.eerp.meta.cache.StateMachineCache;
import com.eerp.meta.statemachine.entity.MetaStateNode;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import com.eerp.meta.statemachine.mapper.MetaStateNodeMapper;
import com.eerp.meta.statemachine.mapper.MetaStateTransitionMapper;
import com.eerp.meta.statemachine.service.MetaStateMachineService;
import com.eerp.meta.statemachine.vo.StateMachineMetaVO;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class StateMachineController {

    private final MetaStateMachineService stateMachineService;
    private final StateMachineCache stateMachineCache;
    private final MetaStateNodeMapper stateNodeMapper;
    private final MetaStateTransitionMapper stateTransitionMapper;
    private final JdbcTemplate jdbcTemplate;

    public StateMachineController(MetaStateMachineService stateMachineService,
                                  StateMachineCache stateMachineCache,
                                  MetaStateNodeMapper stateNodeMapper,
                                  MetaStateTransitionMapper stateTransitionMapper,
                                  JdbcTemplate jdbcTemplate) {
        this.stateMachineService = stateMachineService;
        this.stateMachineCache = stateMachineCache;
        this.stateNodeMapper = stateNodeMapper;
        this.stateTransitionMapper = stateTransitionMapper;
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/bo/{boCode}/states")
    public Result<List<MetaStateNode>> states(@PathVariable String boCode) {
        StateMachineMetaVO vo = stateMachineCache.get(boCode);
        return Result.ok(vo != null ? vo.getNodes() : null);
    }

    @GetMapping("/bo/{boCode}/transitions")
    public Result<List<MetaStateTransition>> transitions(@PathVariable String boCode) {
        StateMachineMetaVO vo = stateMachineCache.get(boCode);
        return Result.ok(vo != null ? vo.getTransitions() : null);
    }

    @PostMapping("/state-node")
    public Result<MetaStateNode> saveNode(@RequestBody MetaStateNode data) {
        stateNodeMapper.insert(data);
        evictByMachineId(data.getMachineId());
        return Result.ok(data);
    }

    @PutMapping("/state-node/{id}")
    public Result<MetaStateNode> updateNode(@PathVariable Long id, @RequestBody MetaStateNode data) {
        data.setId(id);
        stateNodeMapper.updateById(data);
        evictByMachineId(data.getMachineId());
        return Result.ok(data);
    }

    @DeleteMapping("/state-node/{id}")
    public Result<Void> deleteNode(@PathVariable Long id) {
        MetaStateNode existing = stateNodeMapper.selectById(id);
        stateNodeMapper.deleteById(id);
        if (existing != null) {
            evictByMachineId(existing.getMachineId());
        }
        return Result.ok();
    }

    @PutMapping("/state-node/{id}/position")
    public Result<Void> saveNodePosition(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        MetaStateNode node = new MetaStateNode();
        node.setId(id);
        node.setPosX(toInt(body.get("pos_x")));
        node.setPosY(toInt(body.get("pos_y")));
        stateNodeMapper.updateById(node);
        MetaStateNode existing = stateNodeMapper.selectById(id);
        if (existing != null) {
            evictByMachineId(existing.getMachineId());
        }
        return Result.ok();
    }

    @PostMapping("/transition")
    public Result<MetaStateTransition> saveTransition(@RequestBody MetaStateTransition data) {
        stateTransitionMapper.insert(data);
        evictByMachineId(data.getMachineId());
        return Result.ok(data);
    }

    @PutMapping("/transition/{id}")
    public Result<MetaStateTransition> updateTransition(@PathVariable Long id, @RequestBody MetaStateTransition data) {
        data.setId(id);
        stateTransitionMapper.updateById(data);
        evictByMachineId(data.getMachineId());
        return Result.ok(data);
    }

    @DeleteMapping("/transition/{id}")
    public Result<Void> deleteTransition(@PathVariable Long id) {
        MetaStateTransition existing = stateTransitionMapper.selectById(id);
        stateTransitionMapper.deleteById(id);
        if (existing != null) {
            evictByMachineId(existing.getMachineId());
        }
        return Result.ok();
    }

    @GetMapping("/bo/{boCode}/op-logs")
    public Result<List<Map<String, Object>>> opLogs(@PathVariable String boCode) {
        List<Map<String, Object>> logs = jdbcTemplate.queryForList(
                "SELECT * FROM biz_op_log WHERE bo_code = ? ORDER BY op_time DESC LIMIT 200", boCode);
        return Result.ok(logs);
    }

    private void evictByMachineId(Long machineId) {
        if (machineId == null) {
            return;
        }
        com.eerp.meta.statemachine.entity.MetaStateMachine machine = stateMachineService.getById(machineId);
        if (machine != null && machine.getCode() != null) {
            stateMachineCache.evict(machine.getCode());
        }
    }

    private Integer toInt(Object v) {
        if (v == null) {
            return null;
        }
        if (v instanceof Number) {
            return ((Number) v).intValue();
        }
        try {
            return Integer.parseInt(v.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}

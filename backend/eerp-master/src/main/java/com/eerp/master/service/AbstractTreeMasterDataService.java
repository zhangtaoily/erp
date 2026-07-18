package com.eerp.master.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.common.exception.ServiceException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.*;

/**
 * 树形主数据 CRUD 抽象基类（对齐设计文档 06 §3.2）。
 *
 * <p>适用于 parent_id 自引用建模多级树的主数据：组织（sys_org）、部门（sys_dept）、
 * 物料分组（md_material_group）、原料分组（md_raw_material_group）、色系（md_color_series）。</p>
 *
 * <p>提供递归查询子树、层级路径缓存（path 物化）、环路检测（visited Set）、拖拽排序能力。</p>
 *
 * @param <T> 实体类型
 */
public abstract class AbstractTreeMasterDataService<T> extends AbstractMasterDataService<T> {

    @Autowired
    protected JdbcTemplate jdbcTemplate;

    /** 主表名（子类返回，如 "sys_org"） */
    protected abstract String tableName();

    /** parent_id 列名（默认 "parent_id"） */
    protected String parentIdColumn() {
        return "parent_id";
    }

    /** 获取实体的 parentId（子类可重写以适配不同字段名） */
    protected abstract Long getParentId(T entity);

    /** 获取实体ID */
    protected abstract Long getId(T entity);

    /** 获取实体名称（用于路径展示） */
    protected abstract String getName(T entity);

    /**
     * 查询整棵树（从 rootId 开始递归）。
     *
     * @param rootId 根节点ID（null 表示全表）
     * @return 树形结构列表（每个节点含 children）
     */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> listTree(Long rootId) {
        String parentCol = parentIdColumn();
        // 一次性查全表，内存中构建树
        List<Map<String, Object>> all = jdbcTemplate.queryForList(
                "SELECT * FROM " + tableName() + " ORDER BY sort_index, id");
        return buildTree(all, rootId, parentCol);
    }

    /** 查询直接子节点 */
    public List<Map<String, Object>> listChildren(Long parentId) {
        String parentCol = parentIdColumn();
        if (parentId == null) {
            return jdbcTemplate.queryForList(
                    "SELECT * FROM " + tableName() + " WHERE " + parentCol + " IS NULL ORDER BY sort_index, id");
        }
        return jdbcTemplate.queryForList(
                "SELECT * FROM " + tableName() + " WHERE " + parentCol + " = ? ORDER BY sort_index, id", parentId);
    }

    /** 构建层级路径（如 "/1/2/3/"） */
    public String buildPath(Long id) {
        StringBuilder path = new StringBuilder();
        Set<Long> visited = new HashSet<>();
        Long currentId = id;
        String parentCol = parentIdColumn();
        while (currentId != null && !visited.contains(currentId)) {
            visited.add(currentId);
            path.insert(0, "/" + currentId);
            Map<String, Object> row = null;
            try {
                List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                        "SELECT " + parentCol + " FROM " + tableName() + " WHERE id = ?", currentId);
                if (!rows.isEmpty()) {
                    row = rows.get(0);
                }
            } catch (Exception e) {
                break;
            }
            if (row == null) {
                break;
            }
            Object pid = row.get(parentCol);
            if (pid == null) {
                break;
            }
            currentId = ((Number) pid).longValue();
        }
        return path.append("/").toString();
    }

    /** 是否有子节点 */
    public boolean hasChildren(Long id) {
        String parentCol = parentIdColumn();
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM " + tableName() + " WHERE " + parentCol + " = ?", Integer.class, id);
        return count != null && count > 0;
    }

    /**
     * 移动节点（含环路检测）。
     *
     * @param id           要移动的节点ID
     * @param newParentId  新父节点ID（null 表示移到根）
     * @param sortIndex    排序序号
     */
    public void moveNode(Long id, Long newParentId, int sortIndex) {
        if (detectCycle(id, newParentId)) {
            throw new ServiceException("MASTER_TREE_001", "移动节点会形成环路");
        }
        String parentCol = parentIdColumn();
        jdbcTemplate.update(
                "UPDATE " + tableName() + " SET " + parentCol + " = ?, sort_index = ? WHERE id = ?",
                newParentId, sortIndex, id);
    }

    /**
     * 环路检测：检查 newParentId 是否是 id 的子孙节点。
     *
     * @param id          要移动的节点
     * @param newParentId 新父节点
     * @return true 表示会形成环路
     */
    public boolean detectCycle(Long id, Long newParentId) {
        if (id == null || newParentId == null) {
            return false;
        }
        if (id.equals(newParentId)) {
            return true;
        }
        // 向上遍历 newParentId 的祖先链，检查是否经过 id
        String parentCol = parentIdColumn();
        Set<Long> visited = new HashSet<>();
        Long current = newParentId;
        while (current != null && !visited.contains(current)) {
            if (current.equals(id)) {
                return true;
            }
            visited.add(current);
            List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                    "SELECT " + parentCol + " FROM " + tableName() + " WHERE id = ?", current);
            if (rows.isEmpty()) {
                break;
            }
            Object pid = rows.get(0).get(parentCol);
            if (pid == null) {
                break;
            }
            current = ((Number) pid).longValue();
        }
        return false;
    }

    // ---------------- 内部工具 ----------------

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> buildTree(List<Map<String, Object>> all, Long rootId, String parentCol) {
        // 构建 parentId -> children 映射
        Map<Long, List<Map<String, Object>>> childrenMap = new HashMap<>();
        for (Map<String, Object> row : all) {
            Object pidObj = row.get(parentCol);
            Long pid = pidObj != null ? ((Number) pidObj).longValue() : null;
            childrenMap.computeIfAbsent(pid, k -> new ArrayList<>()).add(row);
        }
        // 从 rootId 的子节点开始递归
        return buildChildren(rootId, childrenMap);
    }

    private List<Map<String, Object>> buildChildren(Long parentId, Map<Long, List<Map<String, Object>>> childrenMap) {
        List<Map<String, Object>> children = childrenMap.get(parentId);
        if (children == null) {
            return new ArrayList<>();
        }
        for (Map<String, Object> child : children) {
            Long childId = ((Number) child.get("id")).longValue();
            List<Map<String, Object>> subChildren = buildChildren(childId, childrenMap);
            child.put("children", subChildren);
        }
        return children;
    }
}

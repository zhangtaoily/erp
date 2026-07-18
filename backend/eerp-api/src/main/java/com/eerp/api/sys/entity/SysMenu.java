package com.eerp.api.sys.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 系统菜单
 * <p>支持多级树形结构：directory（目录）/ menu（菜单）/ button（按钮，预留）。
 * 菜单数据持久化到 sys_menu 表，前端启动时从后端加载并构建侧边栏。</p>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_menu")
public class SysMenu extends BaseEntity {

    /** 菜单编码（唯一） */
    private String menuCode;

    /** 菜单名称 */
    private String menuName;

    /** 父菜单 ID（NULL 或 0 表示根菜单） */
    private Long parentId;

    /** 菜单类型：directory 目录 / menu 菜单 / button 按钮 */
    private String menuType;

    /** 路由路径（menu 类型必填，如 /bos/business-object） */
    private String path;

    /** 图标（Element Plus 图标名，如 DataBoard） */
    private String icon;

    /** 排序号（升序） */
    private Integer sortIndex;

    /** 是否显示（1显示 0隐藏） */
    private Integer visible;

    /** 启用状态（1启用 0停用） */
    private Integer status;

    /** 备注 */
    private String remark;

    /** 子菜单（非持久化，用于构建树） */
    @TableField(exist = false)
    private List<SysMenu> children = new ArrayList<>();

    /** 该表无审计字段 create_by/update_by，排除映射 */
    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}

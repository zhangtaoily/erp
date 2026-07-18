package com.eerp.master.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.master.entity.SysOrg;
import org.apache.ibatis.annotations.Mapper;

/**
 * 组织主数据 Mapper（master 模块）。
 *
 * <p>类名使用 {@code Md} 前缀以避免与 {@code com.eerp.api.sys.mapper.SysOrgMapper}
 * 在 {@code @MapperScan("com.eerp")} 下产生 Bean 名称冲突。</p>
 */
@Mapper
public interface MdOrgMapper extends BaseMapper<SysOrg> {
}

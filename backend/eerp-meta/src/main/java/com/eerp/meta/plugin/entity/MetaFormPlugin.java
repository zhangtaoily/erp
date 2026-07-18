package com.eerp.meta.plugin.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 插件绑定（金蝶BOS三基类，script/api/class三种类型）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_form_plugin")
public class MetaFormPlugin extends BaseEntity {

    /** 插件编码（唯一，如 SO_AFTER_AUDIT） */
    private String pluginCode;

    /** 插件名称 */
    private String pluginName;

    /** 所属业务对象编码 */
    private String boCode;

    /** 系统基类：BillPlugin表单/ListPlugin列表/OperationServicePlugin操作服务 */
    private String baseClass;

    /** 绑定事件（按基类决定可选事件集） */
    private String eventName;

    /** 字段级事件触发字段（如 DataChanged 事件的 mat_id/qty） */
    private String fieldCode;

    /** 插件类型：script脚本/api外部API/class Java类 */
    private String pluginType;

    /** 执行顺序（升序，前置返回false或抛异常阻断后续） */
    private Integer execOrder;

    /** 状态：0停用 1启用 */
    private Integer status;

    /** 备注 */
    private String remark;

    /** 脚本内容（plugin_type=script，ANTLR4表达式引擎） */
    private String scriptContent;

    /** API地址（plugin_type=api） */
    private String apiUrl;

    /** HTTP方法（GET/POST/PUT/DELETE） */
    private String apiMethod;

    /** API请求头JSON */
    private String apiHeaders;

    /** API超时秒数 */
    private Integer apiTimeout;

    /** 实现类全限定名（系统反射自动识别） */
    private String className;

    /** 上传的 class/jar 文件路径（系统自动存储） */
    private String classFile;

    /** 继承的系统基类全限定名（系统反射 superclass 链自动识别） */
    private String classBase;
}

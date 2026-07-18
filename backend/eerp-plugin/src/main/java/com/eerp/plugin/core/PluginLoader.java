package com.eerp.plugin.core;

import com.eerp.meta.plugin.entity.MetaFormPlugin;
import com.eerp.meta.plugin.entity.MetaPluginParam;
import com.eerp.meta.plugin.mapper.MetaPluginParamMapper;
import com.eerp.meta.plugin.service.MetaFormPluginService;
import com.eerp.plugin.annotation.BehaviorParam;
import com.eerp.plugin.annotation.FormParam;
import com.eerp.plugin.script.ScriptEngine;
import com.eerp.plugin.script.ScriptPluginAdapter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 插件加载器（对齐 PRD 6.2.7 / 设计文档 §3.2.8）。
 *
 * <p>从 {@link MetaFormPluginService} 查询 bo 绑定的插件配置，按事件过滤、exec_order 排序，
 * 对每个插件配置：
 * <ol>
 *   <li>JAVA 类型：{@code Class.forName(className)} 加载，反射 superclass 链识别三基类并实例化；</li>
 *   <li>SCRIPT 类型：用 {@link ScriptPluginAdapter} 包装脚本表达式为操作服务插件；</li>
 *   <li>扫描实例字段 {@code @FormParam} / {@code @BehaviorParam} 注解，生成参数描述符列表；</li>
 *   <li>从 {@code meta_plugin_param} 表加载参数值（按 param_type 自动注入 behavior 参数）。</li>
 * </ol>
 * 返回 {@link LoadedPlugin} 列表。</p>
 */
@Service
public class PluginLoader {

    /** 三基类全限定名 */
    private static final String BASE_BILL = "com.eerp.plugin.base.AbstractBillPlugin";
    private static final String BASE_LIST = "com.eerp.plugin.base.AbstractListPlugin";
    private static final String BASE_OPERATION = "com.eerp.plugin.base.AbstractOperationServicePlugin";

    private final MetaFormPluginService metaFormPluginService;
    private final MetaPluginParamMapper metaPluginParamMapper;
    private final ScriptEngine scriptEngine;

    @Autowired
    public PluginLoader(MetaFormPluginService metaFormPluginService,
                        MetaPluginParamMapper metaPluginParamMapper,
                        ScriptEngine scriptEngine) {
        this.metaFormPluginService = metaFormPluginService;
        this.metaPluginParamMapper = metaPluginParamMapper;
        this.scriptEngine = scriptEngine;
    }

    /**
     * 加载指定业务对象 + 事件的插件列表（按 exec_order 升序）。
     *
     * @param boCode    业务对象编码
     * @param eventType 事件（阶段方法名，如 beforeExecuteOperationTransaction）
     * @return 已加载插件列表
     */
    public List<LoadedPlugin> loadPlugins(String boCode, String eventType) {
        List<LoadedPlugin> loaded = new ArrayList<>();
        List<MetaFormPlugin> configs = metaFormPluginService.listByBoCode(boCode);
        if (configs == null) {
            return loaded;
        }
        for (MetaFormPlugin cfg : configs) {
            if (cfg.getEventName() == null) {
                continue;
            }
            // 事件名大小写不敏感匹配（兼容 PascalCase 事件名与 camelCase 方法名）
            if (!eventType.equalsIgnoreCase(cfg.getEventName())) {
                continue;
            }
            if (cfg.getStatus() == null || cfg.getStatus() != 1) {
                continue;
            }
            LoadedPlugin lp = loadOne(cfg);
            if (lp != null) {
                loaded.add(lp);
            }
        }
        loaded.sort(Comparator.comparingInt(p -> p.getExecOrder() == null ? Integer.MAX_VALUE : p.getExecOrder()));
        return loaded;
    }

    /** 加载单个插件配置 */
    private LoadedPlugin loadOne(MetaFormPlugin cfg) {
        String type = cfg.getPluginType();
        Object instance;
        String baseClass;
        if (isJavaType(type)) {
            if (cfg.getClassName() == null || cfg.getClassName().trim().isEmpty()) {
                return null;
            }
            try {
                Class<?> clazz = Class.forName(cfg.getClassName());
                baseClass = identifyBaseClass(clazz);
                if (baseClass == null) {
                    return null;
                }
                instance = clazz.getDeclaredConstructor().newInstance();
            } catch (Exception e) {
                throw new RuntimeException("加载 Java 插件失败: " + cfg.getPluginCode()
                        + " - " + e.getMessage(), e);
            }
        } else if (isScriptType(type)) {
            Map<String, String> scripts = new HashMap<>();
            if (cfg.getScriptContent() != null) {
                scripts.put(cfg.getEventName(), cfg.getScriptContent());
            }
            instance = new ScriptPluginAdapter(scripts, scriptEngine);
            baseClass = "OPERATION_SERVICE";
        } else {
            // api 等其它类型暂不支持
            return null;
        }

        List<PluginParamDescriptor> descriptors = scanParams(instance.getClass());
        loadParamValues(cfg.getPluginCode(), descriptors, instance);

        LoadedPlugin lp = new LoadedPlugin();
        lp.setPluginInstance(instance);
        lp.setBaseClass(baseClass);
        lp.setExecOrder(cfg.getExecOrder());
        lp.setParams(descriptors);
        return lp;
    }

    private boolean isJavaType(String type) {
        return type != null && (type.equalsIgnoreCase("JAVA") || type.equalsIgnoreCase("class"));
    }

    private boolean isScriptType(String type) {
        return type != null && (type.equalsIgnoreCase("SCRIPT") || type.equalsIgnoreCase("script"));
    }

    /**
     * 反射 superclass 链识别三基类。
     *
     * @return BILL / LIST / OPERATION_SERVICE；未匹配返回 null
     */
    private String identifyBaseClass(Class<?> clazz) {
        Class<?> c = clazz;
        while (c != null && c != Object.class) {
            String name = c.getName();
            if (BASE_BILL.equals(name)) {
                return "BILL";
            }
            if (BASE_LIST.equals(name)) {
                return "LIST";
            }
            if (BASE_OPERATION.equals(name)) {
                return "OPERATION_SERVICE";
            }
            c = c.getSuperclass();
        }
        return null;
    }

    /** 扫描类继承链上的 @FormParam / @BehaviorParam 字段，生成参数描述符 */
    private List<PluginParamDescriptor> scanParams(Class<?> clazz) {
        List<PluginParamDescriptor> list = new ArrayList<>();
        Class<?> c = clazz;
        while (c != null && c != Object.class) {
            for (Field f : c.getDeclaredFields()) {
                FormParam fp = f.getAnnotation(FormParam.class);
                if (fp != null) {
                    PluginParamDescriptor d = new PluginParamDescriptor();
                    d.setParamName(fp.value());
                    d.setParamType(inferParamType(f.getType()));
                    d.setDescription(fp.description());
                    d.setRequired(fp.required());
                    list.add(d);
                    continue;
                }
                BehaviorParam bp = f.getAnnotation(BehaviorParam.class);
                if (bp != null) {
                    PluginParamDescriptor d = new PluginParamDescriptor();
                    d.setParamName(bp.value());
                    d.setParamType("BEHAVIOR");
                    d.setDescription(bp.description());
                    d.setRequired(false);
                    list.add(d);
                }
            }
            c = c.getSuperclass();
        }
        return list;
    }

    /** 由字段类型推断表单参数类型 */
    private String inferParamType(Class<?> fieldType) {
        if (fieldType == String.class) {
            return "STRING";
        }
        if (fieldType == Boolean.class || fieldType == boolean.class) {
            return "BOOLEAN";
        }
        if (Number.class.isAssignableFrom(fieldType) || fieldType.isPrimitive()) {
            return "NUMBER";
        }
        return "STRING";
    }

    /** 从 meta_plugin_param 表加载参数值，按 param_type 自动注入 */
    private void loadParamValues(String pluginCode, List<PluginParamDescriptor> descriptors, Object instance) {
        if (pluginCode == null || descriptors.isEmpty()) {
            return;
        }
        List<MetaPluginParam> rows;
        try {
            rows = metaPluginParamMapper.listByPluginCode(pluginCode);
        } catch (Exception e) {
            return;
        }
        if (rows == null) {
            return;
        }
        for (MetaPluginParam row : rows) {
            PluginParamDescriptor d = findDescriptor(descriptors, row.getParamKey());
            if (d == null) {
                continue;
            }
            if ("behavior".equalsIgnoreCase(row.getParamType())) {
                d.setValue(row.getDefaultValue());
                injectBehaviorField(instance, row.getParamKey(), row.getDefaultValue());
            } else {
                // form 类型运行时由 billData 注入，此处仅记录占位
                d.setValue(null);
            }
        }
    }

    private PluginParamDescriptor findDescriptor(List<PluginParamDescriptor> descriptors, String key) {
        for (PluginParamDescriptor d : descriptors) {
            if (d.getParamName() != null && d.getParamName().equals(key)) {
                return d;
            }
        }
        return null;
    }

    /** 注入 behavior 参数值到字段 */
    private void injectBehaviorField(Object instance, String paramName, String value) {
        if (instance == null || value == null) {
            return;
        }
        Class<?> c = instance.getClass();
        while (c != null && c != Object.class) {
            for (Field f : c.getDeclaredFields()) {
                BehaviorParam bp = f.getAnnotation(BehaviorParam.class);
                if (bp != null && bp.value().equals(paramName)) {
                    try {
                        f.setAccessible(true);
                        f.set(instance, parseValue(value, f.getType()));
                    } catch (Exception ignored) {
                        // 注入失败保留字段默认值
                    }
                    return;
                }
            }
            c = c.getSuperclass();
        }
    }

    /** 按字段类型解析字符串值 */
    private Object parseValue(String val, Class<?> type) {
        if (type == String.class) {
            return val;
        }
        if (type == Integer.class || type == int.class) {
            return Integer.valueOf(val);
        }
        if (type == Long.class || type == long.class) {
            return Long.valueOf(val);
        }
        if (type == Double.class || type == double.class) {
            return Double.valueOf(val);
        }
        if (type == Float.class || type == float.class) {
            return Float.valueOf(val);
        }
        if (type == Boolean.class || type == boolean.class) {
            return Boolean.valueOf(val);
        }
        if (type == BigDecimal.class) {
            return new BigDecimal(val);
        }
        return val;
    }
}

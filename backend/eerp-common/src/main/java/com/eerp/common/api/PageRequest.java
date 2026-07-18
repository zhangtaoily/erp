package com.eerp.common.api;

import lombok.Data;

/**
 * 分页请求
 */
@Data
public class PageRequest {

    private int pageNum = 1;

    private int pageSize = 20;

    private String orderBy;
}

// springboot/src/main/java/com/example/springboot/dto/common/PageResponse.java
package com.example.springboot.dto.common;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.util.List;

@Data
@AllArgsConstructor
public class PageResponse<T> {
    private List<T> content;      // 分页数据列表
    private long totalElements;   // 总条数
    private int totalPages;       // 总页数
    private int currentPage;      // 当前页码
    private int pageSize;         // 每页条数
}
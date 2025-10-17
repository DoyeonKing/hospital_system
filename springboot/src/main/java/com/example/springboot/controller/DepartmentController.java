package com.example.springboot.controller;

import com.example.springboot.dto.department.DepartmentDTO;
import com.example.springboot.dto.department.DepartmentQueryDTO; // <-- 引入查询 DTO
import com.example.springboot.dto.department.DepartmentResponseDTO;
import com.example.springboot.service.DepartmentService;
import org.springframework.data.domain.Page; // <-- 引入 Page
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List; // 【新增】导入List

// ==========================================================
// 【新增导入】
import com.example.springboot.service.DoctorService;
import com.example.springboot.dto.doctor.AddDoctorRequest;
import com.example.springboot.dto.doctor.DoctorResponse; // 【注意】使用您提供的类名 DoctorResponse
import com.example.springboot.dto.department.DepartmentDoctorsResponseDTO; // 【新增】科室医生列表响应DTO
// ==========================================================

@RestController
@RequestMapping("/api/departments")
public class DepartmentController {

    private final DepartmentService departmentService;
    private final DoctorService doctorService; // 【新增 Service 注入】

    public DepartmentController(DepartmentService departmentService, DoctorService doctorService) { // 【修改构造函数】
        this.departmentService = departmentService;
        this.doctorService = doctorService;
    }

    /**
     * 创建新科室接口
     * 接收: { name: "新科室名", parentDepartmentName: "上级科室名", description: "描述" }
     * 
     * @param departmentDTO 科室数据传输对象
     * @return 创建成功的科室信息
     */
    @PostMapping
    public ResponseEntity<?> createDepartment(@RequestBody DepartmentDTO departmentDTO) {
        try {
            if (departmentDTO.getName() == null || departmentDTO.getName().trim().isEmpty()) {
                return new ResponseEntity<>("科室名称不能为空", HttpStatus.BAD_REQUEST);
            }

            DepartmentResponseDTO createdDepartment = departmentService.createDepartment(departmentDTO);
            return new ResponseEntity<>(createdDepartment, HttpStatus.CREATED);
        } catch (RuntimeException e) {
            // 捕获 Service 层抛出的业务错误 (如上级科室不存在或名称已存在)
            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            // 其他未知错误
            return new ResponseEntity<>("创建科室时发生内部错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 编辑科室描述信息接口
     * 接收: { name: "科室名", description: "新的描述" }
     * 使用 PUT /api/departments/description
     * 
     * @param departmentDTO 包含科室名称和新描述的DTO
     * @return 更新成功的科室信息
     */
    @PutMapping("/description")
    public ResponseEntity<?> updateDepartmentDescription(@RequestBody DepartmentDTO departmentDTO) {
        try {
            if (departmentDTO.getName() == null || departmentDTO.getName().trim().isEmpty()) {
                return new ResponseEntity<>("科室名称不能为空", HttpStatus.BAD_REQUEST);
            }

            // 理论上描述可以为空 (数据库字段是 text)，但为了编辑接口的有效性，这里假设描述不能为空
            if (departmentDTO.getDescription() == null) {
                return new ResponseEntity<>("新的科室描述不能为空", HttpStatus.BAD_REQUEST);
            }

            DepartmentResponseDTO updatedDepartment = departmentService.updateDepartmentDescription(departmentDTO);
            return new ResponseEntity<>(updatedDepartment, HttpStatus.OK);
        } catch (RuntimeException e) {
            // 捕获 Service 层抛出的业务错误 (如科室不存在)
            if (e.getMessage().contains("不存在")) {
                return new ResponseEntity<>(e.getMessage(), HttpStatus.NOT_FOUND); // 404
            }
            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST); // 400
        } catch (Exception e) {
            // 其他未知错误
            return new ResponseEntity<>("编辑科室时发生内部错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 删除科室接口
     * 使用 DELETE /api/departments/{name}
     * 
     * @param name 要删除的科室名称，作为路径变量传入
     * @return 成功删除返回 204 No Content，失败时返回详细错误信息
     */
    @DeleteMapping("/{name}")
    public ResponseEntity<?> deleteDepartment(@PathVariable String name) {
        try {
            if (name == null || name.trim().isEmpty()) {
                return new ResponseEntity<>("科室名称不能为空", HttpStatus.BAD_REQUEST);
            }

            departmentService.deleteDepartmentByName(name);
            // 成功删除，返回 204 No Content，响应体为空
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (RuntimeException e) {
            // 1. 科室不存在的业务错误返回 404
            if (e.getMessage() != null && e.getMessage().contains("不存在")) {
                return new ResponseEntity<>(e.getMessage(), HttpStatus.NOT_FOUND); // 404 Not Found
            }

            // 2. 其他 RuntimeException 返回 400 Bad Request
            String errorMessage = e.getMessage() != null ? e.getMessage() : "未知运行时错误";
            return new ResponseEntity<>(errorMessage, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            // 3. 其他未知错误返回 500 Internal Server Error
            String errorMessage = e.getMessage() != null ? e.getMessage() : "未知内部错误";
            return new ResponseEntity<>("服务器内部错误: " + errorMessage, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ==========================================================
    // 【新增功能接口】往科室里插入医生
    // ==========================================================

    /**
     * 往科室里插入医生接口 (对应前端“添加新成员”弹窗)
     * 【重要】由于 Doctor 实体是 ManyToOne 关系，此操作本质是更新 Doctor 的 department_id 字段。
     * 使用 POST /api/departments/{departmentId}/members
     * 
     * @param departmentId 目标科室的ID
     * @param request      包含医生工号、姓名、职称的请求体 DTO
     * @return 成功返回更新后的医生信息 DoctorResponse
     */
    @PostMapping("/{departmentId}/members")
    public ResponseEntity<DoctorResponse> addDoctorToDepartment( // 【使用 DoctorResponse】
            @PathVariable Integer departmentId,
            @RequestBody AddDoctorRequest request) { // 【使用 AddDoctorRequest】

        // 实际项目中应使用 @Valid 配合全局异常处理
        if (request.getIdentifier() == null || request.getIdentifier().trim().isEmpty() ||
                request.getFullName() == null || request.getFullName().trim().isEmpty() ||
                request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            // 实际项目中应该返回 HttpStatus.BAD_REQUEST，这里简化处理
            throw new IllegalArgumentException("医生ID、姓名和职称不能为空");
        }

        try {
            // 1. 调用 DoctorService 处理业务逻辑
            DoctorResponse updatedDoctor = doctorService.assignDoctorToDepartment(
                    departmentId,
                    request.getIdentifier(),
                    request.getFullName(),
                    request.getTitle());

            // 2. 成功，返回 200 OK
            return new ResponseEntity<>(updatedDoctor, HttpStatus.OK);

        } catch (RuntimeException e) {
            // 业务错误处理 (Controller中不再直接返回字符串，而是抛出异常，由全局处理)
            // 为了保持现有Controller的风格，这里继续使用ResponseEntity<?>返回错误信息
            String message = e.getMessage();
            if (message != null) {
                if (message.contains("不存在")) {
                    return new ResponseEntity(message, HttpStatus.NOT_FOUND); // 404
                } else if (message.contains("已在该科室")) {
                    return new ResponseEntity(message, HttpStatus.CONFLICT); // 409
                }
            }
            return new ResponseEntity(message != null ? message : "请求错误", HttpStatus.BAD_REQUEST); // 400
        } catch (Exception e) {
            // 未知内部错误
            return new ResponseEntity("添加医生时发生内部错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR); // 500
        }
    }
    // ==========================================================
    // 【新增功能接口】删除科室成员
    // ==========================================================

    /**
     * 删除科室成员接口 (对应前端列表的删除按钮)
     * 【注意】这里假设删除操作是基于唯一的医生工号 (identifier) 进行的。
     * 使用 DELETE /api/departments/{departmentId}/members/{identifier}
     * 
     * @param departmentId 目标科室的ID (可选参数，可用于权限或科室校验)
     * @param identifier   要删除的医生的工号
     * @return 成功删除返回 204 No Content
     */
    @DeleteMapping("/{departmentId}/members/{identifier}")
    public ResponseEntity<?> deleteDepartmentMember(
            @PathVariable Integer departmentId,
            @PathVariable String identifier) {

        if (identifier == null || identifier.trim().isEmpty()) {
            return new ResponseEntity<>("医生工号不能为空", HttpStatus.BAD_REQUEST);
        }

        try {
            // 1. 调用 DoctorService 处理删除业务逻辑
            // 注意：DoctorService 的 deleteDoctorByIdentifier 方法只需要 identifier。
            // departmentId 可以在 Service 层用于额外的业务校验（例如：确保只有该科室的管理员可以删除该科室的成员）。
            doctorService.deleteDoctorByIdentifier(identifier);

            // 2. 成功删除，返回 204 No Content
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (RuntimeException e) {
            // 业务错误处理
            String message = e.getMessage();
            if (message != null && message.contains("不存在")) {
                return new ResponseEntity<>(message, HttpStatus.NOT_FOUND); // 404
            }
            return new ResponseEntity<>(message != null ? message : "请求错误", HttpStatus.BAD_REQUEST); // 400
        } catch (Exception e) {
            // 未知内部错误
            return new ResponseEntity<>("删除医生时发生内部错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR); // 500
        }
    }

    // ==========================================================
    // 【新增功能接口】获取科室医生列表
    // ==========================================================

    /**
     * 获取指定科室下的所有医生列表接口
     * 对应前端"查看成员"按钮功能
     * 使用 GET /api/departments/{departmentId}/doctors
     * 
     * @param departmentId 科室ID
     * @return 包含科室信息和医生列表的响应对象
     */
    @GetMapping("/{departmentId}/doctors")
    public ResponseEntity<?> getDepartmentDoctors(@PathVariable Integer departmentId) {
        try {
            // 1. 验证科室ID
            if (departmentId == null) {
                return new ResponseEntity<>("科室ID不能为空", HttpStatus.BAD_REQUEST);
            }

            // 2. 调用 DoctorService 获取该科室下的所有医生
            List<DoctorResponse> doctors = doctorService.getDoctorsByDepartmentId(departmentId);

            // 3. 获取科室信息
            DepartmentResponseDTO department = departmentService.getDepartmentById(departmentId);
            if (department == null) {
                return new ResponseEntity<>("科室不存在", HttpStatus.NOT_FOUND);
            }

            // 4. 构建响应数据
            DepartmentDoctorsResponseDTO response = new DepartmentDoctorsResponseDTO(
                    department.getName(),
                    departmentId,
                    doctors);

            // 5. 返回成功响应
            return new ResponseEntity<>(response, HttpStatus.OK);

        } catch (RuntimeException e) {
            // 业务错误处理
            String message = e.getMessage();
            if (message != null && message.contains("不存在")) {
                return new ResponseEntity<>(message, HttpStatus.NOT_FOUND); // 404
            }
            return new ResponseEntity<>(message != null ? message : "请求错误", HttpStatus.BAD_REQUEST); // 400
        } catch (Exception e) {
            // 未知内部错误
            return new ResponseEntity<>("获取医生列表时发生内部错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR); // 500
        }
    }

    /**
     * 查询和分页获取科室列表接口 (支持按名称、描述搜索、分页和排序)
     * 使用 GET
     * /api/departments?page=0&size=10&name=内科&description=治疗&sortBy=departmentId&sortOrder=desc
     * 
     * @param queryDTO 包含查询条件、分页和排序信息的DTO，通过ModelAttribute自动绑定查询参数
     * @return 包含科室列表和分页信息的响应对象 Page<DepartmentResponseDTO>
     */
    @GetMapping
    public ResponseEntity<Page<DepartmentResponseDTO>> getDepartments(@ModelAttribute DepartmentQueryDTO queryDTO) {
        try {
            // 1. 调用 Service 层实现的查询方法，该方法返回 Page<DepartmentResponseDTO>
            Page<DepartmentResponseDTO> departmentPage = departmentService.queryDepartments(queryDTO);

            // 2. 成功返回 200 OK，Spring Boot 会自动将 Page<DepartmentResponseDTO> 序列化为 JSON
            return new ResponseEntity<>(departmentPage, HttpStatus.OK);
        } catch (Exception e) {
            // 3. 捕获 Service 层可能抛出的异常，返回 500
            // 这里为了符合您的期望调试方式，返回一个包含错误信息的 ResponseEntity<?>
            return new ResponseEntity(
                    "查询科室时发生内部错误: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
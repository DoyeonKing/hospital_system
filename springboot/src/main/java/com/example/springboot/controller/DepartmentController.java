package com.example.springboot.controller;

import com.example.springboot.dto.department.DepartmentDTO;
import com.example.springboot.dto.department.DepartmentQueryDTO;
import com.example.springboot.dto.department.DepartmentResponseDTO;
import com.example.springboot.dto.department.DepartmentTreeDTO;
import com.example.springboot.dto.department.DoctorDataDTO;
import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.entity.ParentDepartment;
import com.example.springboot.service.DepartmentService;
import com.example.springboot.service.ParentDepartmentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/departments")
public class DepartmentController {

    @Autowired
    private DepartmentService departmentService;
    
    @Autowired
    private ParentDepartmentService parentDepartmentService;

    /**
     * 创建新子科室接口
     * 接收: { name: "新科室名", parentDepartmentName: "父科室名", description: "描述" }
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
            
            if (departmentDTO.getParentDepartmentName() == null || departmentDTO.getParentDepartmentName().trim().isEmpty()) {
                return new ResponseEntity<>("父科室名称不能为空", HttpStatus.BAD_REQUEST);
            }

            DepartmentResponseDTO createdDepartment = departmentService.createDepartment(departmentDTO);
            return new ResponseEntity<>(createdDepartment, HttpStatus.CREATED);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
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

            DepartmentResponseDTO updatedDepartment = departmentService.updateDepartmentDescription(departmentDTO);
            return new ResponseEntity<>(updatedDepartment, HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            return new ResponseEntity<>("更新科室时发生内部错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
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
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("不存在")) {
                return new ResponseEntity<>(e.getMessage(), HttpStatus.NOT_FOUND);
            }
            String errorMessage = e.getMessage() != null ? e.getMessage() : "未知运行时错误";
            return new ResponseEntity<>(errorMessage, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            String errorMessage = e.getMessage() != null ? e.getMessage() : "未知内部错误";
            return new ResponseEntity<>("服务器内部错误: " + errorMessage, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 查询和分页获取科室列表接口 (支持按名称、描述搜索、分页和排序)
     * 使用 GET /api/departments?page=0&size=10&name=内科&description=治疗&sortBy=departmentId&sortOrder=desc
     * 
     * @param queryDTO 包含查询条件、分页和排序信息的DTO，通过ModelAttribute自动绑定查询参数
     * @return 包含科室列表和分页信息的响应对象 Page<DepartmentResponseDTO>
     */
    @GetMapping
    public ResponseEntity<Page<DepartmentResponseDTO>> getDepartments(@ModelAttribute DepartmentQueryDTO queryDTO) {
        try {
            Page<DepartmentResponseDTO> departmentPage = departmentService.queryDepartments(queryDTO);
            return new ResponseEntity<>(departmentPage, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity(
                    "查询科室时发生内部错误: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 根据父科室ID获取子科室列表
     * 使用 GET /api/departments/parent/{parentId}
     * 
     * @param parentId 父科室ID
     * @return 子科室列表
     */
    @GetMapping("/parent/{parentId}")
    public ResponseEntity<?> getDepartmentsByParentId(@PathVariable Integer parentId) {
        try {
            List<DepartmentResponseDTO> departments = departmentService.getDepartmentsByParentId(parentId);
            return new ResponseEntity<>(departments, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("查询子科室时发生错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 获取所有父科室列表
     * 使用 GET /api/departments/parents
     * 
     * @return 父科室列表
     */
    @GetMapping("/parents")
    public ResponseEntity<?> getAllParentDepartments() {
        try {
            List<ParentDepartment> parentDepartments = departmentService.getAllParentDepartments();
            return new ResponseEntity<>(parentDepartments, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("查询父科室时发生错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 根据ID获取科室详情
     * 使用 GET /api/departments/{id}
     * 
     * @param id 科室ID
     * @return 科室详情
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getDepartmentById(@PathVariable Integer id) {
        try {
            DepartmentResponseDTO department = departmentService.getDepartmentById(id);
            if (department != null) {
                return new ResponseEntity<>(department, HttpStatus.OK);
            } else {
                return new ResponseEntity<>("科室不存在", HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>("查询科室时发生错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 获取科室树形结构数据（排除ID=999的未分配科室）
     * 使用 GET /api/departments/tree
     * 
     * @return 树形结构的科室数据
     */
    @GetMapping("/tree")
    public ResponseEntity<?> getDepartmentTree() {
        try {
            List<DepartmentTreeDTO> treeData = departmentService.getDepartmentTree();
            return new ResponseEntity<>(treeData, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("获取科室树形数据时发生错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 根据科室ID获取该科室下的医生列表
     * 使用 GET /api/departments/{departmentId}/doctors
     * 
     * @param departmentId 科室ID
     * @return 医生列表
     */
    @GetMapping("/{departmentId}/doctors")
    public ResponseEntity<?> getDoctorsByDepartmentId(@PathVariable Integer departmentId) {
        try {
            List<DoctorResponse> doctors = departmentService.getDoctorsByDepartmentId(departmentId);
            return new ResponseEntity<>(doctors, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("获取科室医生列表时发生错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 将医生添加到指定科室
     * 使用 POST /api/departments/{departmentId}/members
     * 
     * @param departmentId 科室ID
     * @param doctorData 医生信息
     * @return 添加后的医生信息
     */
    @PostMapping("/{departmentId}/members")
    public ResponseEntity<?> addDoctorToDepartment(@PathVariable Integer departmentId, @RequestBody DoctorDataDTO doctorData) {
        try {
            DoctorResponse doctor = departmentService.addDoctorToDepartment(departmentId, doctorData);
            return new ResponseEntity<>(doctor, HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>("添加医生到科室时发生错误: " + e.getMessage(), HttpStatus.BAD_REQUEST);
        }
    }

    /**
     * 从科室中移除医生（将department_id设置为999）
     * 使用 DELETE /api/departments/{departmentId}/members/{doctorIdentifier}
     * 
     * @param departmentId 科室ID
     * @param doctorIdentifier 医生工号
     * @return 操作结果
     */
    @DeleteMapping("/{departmentId}/members/{doctorIdentifier}")
    public ResponseEntity<?> removeDoctorFromDepartment(@PathVariable Integer departmentId, @PathVariable String doctorIdentifier) {
        try {
            departmentService.removeDoctorFromDepartment(departmentId, doctorIdentifier);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (Exception e) {
            return new ResponseEntity<>("从科室移除医生时发生错误: " + e.getMessage(), HttpStatus.BAD_REQUEST);
        }
    }
}
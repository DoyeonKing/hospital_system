// 路径：src/main/java/com/example/springboot/controller/LocationController.java
package com.example.springboot.controller;

import com.example.springboot.entity.Location;
import com.example.springboot.service.LocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/api/locations")
public class LocationController {

    @Autowired
    private LocationService locationService;

    /**
     * 根据科室ID获取门诊室名称列表
     * 
     * @param departmentId 科室ID
     * @return 门诊室名称列表
     */
    @GetMapping("/department/{departmentId}/names")
    public ResponseEntity<?> getLocationNamesByDepartmentId(@PathVariable Integer departmentId) {
        try {
            List<String> locationNames = locationService.getLocationNamesByDepartmentId(departmentId);
            return new ResponseEntity<>(locationNames, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("获取门诊室名称失败: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 根据科室ID获取门诊室完整信息列表
     * 
     * @param departmentId 科室ID
     * @return 门诊室完整信息列表
     */
    @GetMapping("/department/{departmentId}")
    public ResponseEntity<?> getLocationsByDepartmentId(@PathVariable Integer departmentId) {
        try {
            List<Location> locations = locationService.getLocationsByDepartmentId(departmentId);
            return new ResponseEntity<>(locations, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("获取门诊室信息失败: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
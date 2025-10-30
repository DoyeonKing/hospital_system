// 路径：src/main/java/com/example/springboot/service/LocationService.java
package com.example.springboot.service;

import com.example.springboot.entity.Location;
import com.example.springboot.repository.LocationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class LocationService {

    @Autowired
    private LocationRepository locationRepository;

    /**
     * 根据科室ID获取所有门诊室名称
     * 
     * @param departmentId 科室ID
     * @return 门诊室名称列表
     */
    public List<String> getLocationNamesByDepartmentId(Integer departmentId) {
        // 查询该科室下的所有门诊室
        List<Location> locations = locationRepository.findByDepartmentDepartmentId(departmentId);

        // 提取locationName并返回
        return locations.stream()
                .map(Location::getLocationName)
                .collect(Collectors.toList());
    }

    /**
     * 根据科室ID获取所有门诊室完整信息
     * 
     * @param departmentId 科室ID
     * @return 门诊室完整信息列表
     */
    public List<Location> getLocationsByDepartmentId(Integer departmentId) {
        // 查询该科室下的所有门诊室
        return locationRepository.findByDepartmentDepartmentId(departmentId);
    }
}
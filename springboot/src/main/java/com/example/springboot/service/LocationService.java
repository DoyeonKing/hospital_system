package com.example.springboot.service;

import com.example.springboot.dto.location.LocationResponse;
import com.example.springboot.entity.Department;
import com.example.springboot.entity.Location;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.DepartmentRepository;
import com.example.springboot.repository.LocationRepository;
import com.example.springboot.repository.ScheduleRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LocationService {

    private final LocationRepository locationRepository;
    private final DepartmentRepository departmentRepository;
    private final ScheduleRepository scheduleRepository;

    /**
     * 创建地点
     */
    @Transactional
    public Location createLocation(Location location) {
        return locationRepository.save(location);
    }

    /**
     * 为指定科室创建地点（从Map构建）
     */
    @Transactional
    public Location createLocation(Integer departmentId, java.util.Map<String, Object> locationData) {
        // 验证科室是否存在
        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new ResourceNotFoundException("科室不存在，ID: " + departmentId));

        // 构建Location对象
        Location location = new Location();
        location.setDepartment(department);
        
        if (locationData.containsKey("locationName")) {
            location.setLocationName((String) locationData.get("locationName"));
        }
        if (locationData.containsKey("floorLevel")) {
            Object floorLevel = locationData.get("floorLevel");
            if (floorLevel instanceof Integer) {
                location.setFloorLevel((Integer) floorLevel);
            } else if (floorLevel instanceof Number) {
                location.setFloorLevel(((Number) floorLevel).intValue());
            }
        }
        if (locationData.containsKey("building")) {
            location.setBuilding((String) locationData.get("building"));
        }
        if (locationData.containsKey("roomNumber")) {
            location.setRoomNumber((String) locationData.get("roomNumber"));
        }
        if (locationData.containsKey("capacity")) {
            Object capacity = locationData.get("capacity");
            if (capacity instanceof Integer) {
                location.setCapacity((Integer) capacity);
            } else if (capacity instanceof Number) {
                location.setCapacity(((Number) capacity).intValue());
            }
        }
        if (locationData.containsKey("latitude")) {
            Object latitude = locationData.get("latitude");
            if (latitude != null) {
                location.setLatitude(BigDecimal.valueOf(((Number) latitude).doubleValue()));
            }
        }
        if (locationData.containsKey("longitude")) {
            Object longitude = locationData.get("longitude");
            if (longitude != null) {
                location.setLongitude(BigDecimal.valueOf(((Number) longitude).doubleValue()));
            }
        }
        if (locationData.containsKey("addressDetail")) {
            location.setAddressDetail((String) locationData.get("addressDetail"));
        }

        return locationRepository.save(location);
    }

    /**
     * 更新地点
     */
    @Transactional
    public Location updateLocation(Integer locationId, Location locationDetails) {
        Location location = locationRepository.findById(locationId)
                .orElseThrow(() -> new ResourceNotFoundException("地点不存在，ID: " + locationId));
        
        location.setLocationName(locationDetails.getLocationName());
        location.setFloorLevel(locationDetails.getFloorLevel());
        location.setBuilding(locationDetails.getBuilding());
        location.setRoomNumber(locationDetails.getRoomNumber());
        location.setCapacity(locationDetails.getCapacity());
        
        return locationRepository.save(location);
    }

    /**
     * 根据ID获取地点
     */
    public Location getLocationById(Integer locationId) {
        return locationRepository.findById(locationId)
                .orElseThrow(() -> new ResourceNotFoundException("地点不存在，ID: " + locationId));
    }

    /**
     * 获取所有地点
     */
    public List<Location> getAllLocations() {
        return locationRepository.findAll();
    }

    /**
     * 根据科室ID获取地点列表
     */
    public List<LocationResponse> getLocationsByDepartmentId(Integer departmentId) {
        return locationRepository.findByDepartmentDepartmentId(departmentId)
                .stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    /**
     * 根据科室ID获取地点名称列表
     */
    public List<String> getLocationNamesByDepartmentId(Integer departmentId) {
        return locationRepository.findByDepartmentDepartmentId(departmentId)
                .stream()
                .map(Location::getLocationName)
                .filter(name -> name != null && !name.trim().isEmpty())
                .collect(Collectors.toList());
    }

    /**
     * 删除地点
     */
    @Transactional
    public void deleteLocation(Integer locationId) {
        Location location = locationRepository.findById(locationId)
                .orElseThrow(() -> new ResourceNotFoundException("地点不存在，ID: " + locationId));
        locationRepository.delete(location);
    }

    /**
     * 获取所有未分配科室的地点
     * 
     * @return 未分配地点列表
     */
    public List<LocationResponse> getUnassignedLocations() {
        // 查询department为null的地点
        return locationRepository.findAll().stream()
                .filter(location -> location.getDepartment() == null)
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    /**
     * 转换Location实体为LocationResponse DTO
     * 
     * @param location Location实体
     * @return LocationResponse DTO
     */
    private LocationResponse convertToResponse(Location location) {
        LocationResponse response = new LocationResponse();
        response.setLocationId(location.getLocationId());
        response.setLocationName(location.getLocationName());
        response.setFloorLevel(location.getFloorLevel());
        response.setBuilding(location.getBuilding());
        response.setRoomNumber(location.getRoomNumber());
        response.setCapacity(location.getCapacity());
        if (location.getMapNode() != null) {
            response.setMapNodeId(location.getMapNode().getNodeId().longValue());
        } else {
            response.setMapNodeId(null);
        }
        
        if (location.getDepartment() != null) {
            response.setDepartmentId(location.getDepartment().getDepartmentId());
            response.setDepartmentName(location.getDepartment().getName());
        }
        
        return response;
    }

    /**
     * 批量将地点分配到指定科室
     * 
     * @param departmentId 科室ID
     * @param locationIds 地点ID列表
     * @return 分配成功的地点列表
     */
    @Transactional
    public List<LocationResponse> batchAssignLocationsToDepartment(Integer departmentId, List<Integer> locationIds) {
        // 1. 验证科室是否存在
        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new ResourceNotFoundException("科室不存在，ID: " + departmentId));

        // 2. 批量分配地点
        List<LocationResponse> assignedLocations = new java.util.ArrayList<>();
        for (Integer locationId : locationIds) {
            Location location = locationRepository.findById(locationId)
                    .orElseThrow(() -> new ResourceNotFoundException("地点不存在，ID: " + locationId));
            
            location.setDepartment(department);
            Location savedLocation = locationRepository.save(location);
            assignedLocations.add(convertToResponse(savedLocation));
        }

        return assignedLocations;
    }

    /**
     * 将地点从科室中移除（设置department为null）
     * 
     * @param departmentId 科室ID
     * @param locationId 地点ID
     */
    @Transactional
    public void removeLocationFromDepartment(Integer departmentId, Integer locationId) {
        // 1. 验证地点是否存在
        Location location = locationRepository.findById(locationId)
                .orElseThrow(() -> new ResourceNotFoundException("地点不存在，ID: " + locationId));

        // 2. 验证地点是否属于该科室
        if (location.getDepartment() == null || 
            !location.getDepartment().getDepartmentId().equals(departmentId)) {
            throw new RuntimeException("该地点不属于指定科室");
        }

        // 3. 检查地点是否在未来的排班中被使用
        long futureScheduleCount = scheduleRepository.countFutureSchedulesByLocation(
            locationId,
            LocalDate.now()
        );
        if (futureScheduleCount > 0) {
            throw new RuntimeException("该地点在 " + futureScheduleCount + " 个未来的排班中被使用，无法移除。请先删除或调整相关排班。");
        }

        // 4. 移除科室关联
        location.setDepartment(null);
        locationRepository.save(location);
    }
}

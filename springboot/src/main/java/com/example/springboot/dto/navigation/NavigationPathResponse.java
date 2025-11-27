package com.example.springboot.dto.navigation;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class NavigationPathResponse {
    private List<MapNodeDto> nodes = new ArrayList<>();
    private List<NavigationInstructionDto> instructions = new ArrayList<>();
    private List<PathSegmentDto> pathSegments = new ArrayList<>();
    private Double totalDistance;
    private Boolean requiresFloorChange;
    private List<CrossFloorHintDto> crossFloorHints = new ArrayList<>();
}










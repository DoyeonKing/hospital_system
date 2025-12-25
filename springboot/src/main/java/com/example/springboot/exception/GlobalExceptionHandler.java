package com.example.springboot.exception;

import com.example.springboot.common.Result;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;

import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler {

    /**
     * 处理权限拒绝异常
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Result> handleAccessDeniedException(AccessDeniedException ex, WebRequest request) {
        Result errorResponse = Result.error("403", "无权访问：" + ex.getMessage());
        return new ResponseEntity<>(errorResponse, HttpStatus.FORBIDDEN);
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Result> handleResourceNotFoundException(ResourceNotFoundException ex, WebRequest request) {
        Result errorResponse = Result.error("404", ex.getMessage());
        return new ResponseEntity<>(errorResponse, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<Result> handleBadRequestException(BadRequestException ex, WebRequest request) {
        Result errorResponse = Result.error("400", ex.getMessage());
        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }

    /**
     * 处理数据完整性违反异常（外键约束等）
     */
    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    public ResponseEntity<Result> handleDataIntegrityViolationException(org.springframework.dao.DataIntegrityViolationException ex, WebRequest request) {
        String errorMsg = ex.getMessage();
        String friendlyMsg = "操作失败：数据完整性约束违反";
        
        // 🔥 检查是否是外键约束错误
        if (errorMsg != null) {
            if (errorMsg.contains("foreign key constraint") || errorMsg.contains("Cannot delete or update a parent row")) {
                if (errorMsg.contains("appointments")) {
                    friendlyMsg = "无法删除排班：该排班存在关联的预约记录，请先处理相关预约后再删除";
                } else {
                    friendlyMsg = "无法删除：该记录存在关联数据，请先处理相关记录";
                }
            }
        }
        
        Result errorResponse = Result.error("400", friendlyMsg);
        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Result> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
                errors.put(error.getField(), error.getDefaultMessage()));

        Result errorResponse = Result.error("400", "参数验证失败");
        errorResponse.setData(errors);
        return new ResponseEntity<>(errorResponse, HttpStatus.OK);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Result> handleGlobalException(Exception ex, WebRequest request) {
        Result errorResponse = Result.error("500", ex.getMessage());
        return new ResponseEntity<>(errorResponse, HttpStatus.OK);
    }
}

package com.poscaisse.web;

import com.poscaisse.dto.AuthDtos.*;
import com.poscaisse.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController @RequestMapping("/api/auth") @RequiredArgsConstructor
public class AuthController {
    private final AuthService auth;

    @GetMapping("/users") public List<UserTile> users() { return auth.userTiles(); }
    @PostMapping("/pin") public AuthResponse pin(@Valid @RequestBody PinLoginRequest req) { return auth.loginWithPin(req); }
    @PostMapping("/login") public AuthResponse login(@Valid @RequestBody LoginRequest req) { return auth.loginWithPassword(req); }
    @GetMapping("/me") public AuthResponse me() { return auth.me(); }
    @PostMapping("/logout") public Map<String, Boolean> logout() { auth.logout(); return Map.of("ok", true); }
    @PostMapping("/change-pin") public Map<String, Boolean> changePin(@Valid @RequestBody ChangePinRequest req) { auth.changePin(req); return Map.of("ok", true); }
}

package estufa.empresa.controller

import estufa.empresa.service.AccessGuardService
import estufa.empresa.service.AuthService
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api")
class AuthController {

    private final AuthService authService
    private final AccessGuardService accessGuard

    AuthController(AuthService authService, AccessGuardService accessGuard) {
        this.authService = authService
        this.accessGuard = accessGuard
    }

    @PostMapping("/auth/login")
    Map<String, Object> login(@RequestBody Map<String, String> payload) {
        authService.login(payload.login, payload.senha)
    }

    @PostMapping("/auth/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void logout(@RequestHeader(value = "Authorization", required = false) String authorization) {
        String token = authorization?.startsWith("Bearer ") ? authorization.substring(7) : null
        authService.logout(token)
    }

    @GetMapping("/internal/auth/me")
    Map<String, Object> me(HttpServletRequest request) {
        def usuario = accessGuard.usuarioLogado(request)
        authService.me(usuario)
    }
}

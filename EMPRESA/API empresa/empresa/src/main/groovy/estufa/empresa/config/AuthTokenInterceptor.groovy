package estufa.empresa.config

import estufa.empresa.service.AuthService
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.servlet.HandlerInterceptor

@Component
class AuthTokenInterceptor implements HandlerInterceptor {

    private final AuthService authService

    AuthTokenInterceptor(AuthService authService) {
        this.authService = authService
    }

    @Override
    boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String path = request.requestURI ?: ""

        if (path.startsWith("/api/public/") || path.startsWith("/api/auth/") || path == "/api/dashboard/health") {
            return true
        }

        if (!path.startsWith("/api/internal/")) {
            return true
        }

        String authHeader = request.getHeader("Authorization")
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            response.sendError(HttpStatus.UNAUTHORIZED.value(), "Token não informado")
            return false
        }

        String token = authHeader.substring(7)
        def usuario = authService.autenticarToken(token)
        if (usuario == null) {
            response.sendError(HttpStatus.UNAUTHORIZED.value(), "Token inválido ou expirado")
            return false
        }

        request.setAttribute("authUser", usuario)
        return true
    }
}

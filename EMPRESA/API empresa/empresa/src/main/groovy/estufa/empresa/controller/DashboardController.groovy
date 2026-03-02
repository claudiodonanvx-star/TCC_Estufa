package estufa.empresa.controller

import estufa.empresa.service.DashboardService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping
class DashboardController {

    private final DashboardService dashboardService

    DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService
    }

    @GetMapping("/api/dashboard/health")
    Map<String, Object> health() {
        [status: "ok", service: "empresa-api"]
    }

    @GetMapping("/api/internal/dashboard/resumo")
    Map<String, Object> resumo() {
        dashboardService.resumoGeral()
    }
}

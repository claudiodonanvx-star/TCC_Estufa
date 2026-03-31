package estufa.empresa

import org.springframework.boot.SpringApplication
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.scheduling.annotation.EnableScheduling

@SpringBootApplication
@EnableScheduling
class EmpresaApplication {

	static void main(String[] args) {
		SpringApplication.run(EmpresaApplication, args)
	}

}

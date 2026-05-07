package com.example.apiProjeto;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@ComponentScan(basePackages = {"com.example.apiProjeto", "org.example.controller"})
public class ApiProjetoApplication {

	public static void main(String[] args) {
		SpringApplication.run(ApiProjetoApplication.class, args);
	}

}

package com.example.apiProjeto.controller;

import com.example.apiProjeto.model.Cultivo;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class CultivoControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void criarCultivo_comDadosValidos_retornarCreated() throws Exception {
        Cultivo cultivo = new Cultivo();
        cultivo.setNome("Tomate");
        cultivo.setTipo("Fruta");
        cultivo.setTemperaturaMinima(18.0f);
        cultivo.setTemperaturaMaxima(28.0f);
        cultivo.setUmidadeMinima(60.0f);
        cultivo.setUmidadeMaxima(80.0f);
        cultivo.setUmidadeSoloMinima(40.0f);
        cultivo.setUmidadeSoloMaxima(60.0f);

        mockMvc.perform(post("/api/cultivos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cultivo)))
                .andExpect(status().isCreated())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
    }

    @Test
    void criarCultivo_comTemperaturaInvalida_retornarBadRequest() throws Exception {
        Cultivo cultivo = new Cultivo();
        cultivo.setNome("Alface");
        cultivo.setTipo("Verdura");
        cultivo.setTemperaturaMinima(25.0f);
        cultivo.setTemperaturaMaxima(20.0f);
        cultivo.setUmidadeMinima(60.0f);
        cultivo.setUmidadeMaxima(80.0f);
        cultivo.setUmidadeSoloMinima(40.0f);
        cultivo.setUmidadeSoloMaxima(60.0f);

        mockMvc.perform(post("/api/cultivos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cultivo)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value(containsString("temperatura")));
    }
}

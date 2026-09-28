package com.example.taskmaster.presentation;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import tools.jackson.databind.ObjectMapper;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

// 測定用（記事には載せない）。POST と PUT に空のタイトルを送り、返るステータスと本文を標準出力へ出す。判定はしない
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class PutBlankTitleProbeTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:17-alpine");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void probe() throws Exception {
        MvcResult blankPost = mockMvc.perform(post("/api/tasks")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"\",\"description\":\"d\",\"dueDate\":\"2026-06-01\"}")).andReturn();
        System.out.println("PROBE POST_BLANK status=" + blankPost.getResponse().getStatus()
                + " body=" + blankPost.getResponse().getContentAsString());

        MvcResult created = mockMvc.perform(post("/api/tasks")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"元のタイトル\",\"description\":\"d\",\"dueDate\":\"2026-06-01\"}")).andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).get("id").asLong();

        MvcResult blankPut = mockMvc.perform(put("/api/tasks/" + id)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"\",\"description\":\"d\",\"dueDate\":\"2026-06-01\"}")).andReturn();
        System.out.println("PROBE PUT_BLANK status=" + blankPut.getResponse().getStatus()
                + " body=" + blankPut.getResponse().getContentAsString());
    }
}

package com.example.apiProjeto.model;

import jakarta.persistence.*;

@Entity
@Table(name = "ipexterno")
public class IpExterno {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "ip", nullable = false)
    private String ip;

    public IpExterno() {}

    public IpExterno(String ip) {
        this.ip = ip;
    }

    public Long getId() {
        return id;
    }

    public String getIp() {
        return ip;
    }

    public void setIp(String ip) {
        this.ip = ip;
    }
}

package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

@Entity @Table(name = "app_setting") @Getter @Setter
public class AppSetting {
    @Id @Column(name = "setting_key") private String key;
    @Column(name = "setting_value", columnDefinition = "text") private String value;
    private OffsetDateTime updatedAt = OffsetDateTime.now();
}

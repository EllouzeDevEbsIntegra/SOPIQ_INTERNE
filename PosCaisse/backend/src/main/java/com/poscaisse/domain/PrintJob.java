package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

@Entity @Table(name = "print_job") @Getter @Setter
public class PrintJob {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_id") private SaleOrder order;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "destination_id") private PrintDestination destination;
    private String destinationCode;
    private String title;
    private int copies = 1;
    @Column(columnDefinition = "text") private String content;
    @Enumerated(EnumType.STRING) private Enums.PrintJobStatus status = Enums.PrintJobStatus.PENDING;
    private boolean duplicate;
    private OffsetDateTime createdAt = OffsetDateTime.now();
    private OffsetDateTime printedAt;
}

package com.vrms.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Entity
@Table(name = "agency_config")
@Data
@Builder
@AllArgsConstructor
public class AgencyConfig {

    @Id
    @Builder.Default
    private String id = "default";

    @Builder.Default
    private String companyName = "DriveLine";

    @Builder.Default
    private String companySlogan = "CAR RENTAL";

    @Builder.Default
    private String phone = "+855 23 999 888";

    @Builder.Default
    private String email = "booking@driveline-rental.com";

    @Builder.Default
    private String address = "Phnom Penh & Siem Reap, Cambodia";

    private String logoUrl;

    private String paymentQrUrl;

    @Builder.Default
    private String bankName = "ABA Bank";

    @Builder.Default
    private String accountName = "DriveLine Rental";

    @Builder.Default
    private String accountNumber = "000 892 112";

    private String khqrData;

    public AgencyConfig() {
    }
}

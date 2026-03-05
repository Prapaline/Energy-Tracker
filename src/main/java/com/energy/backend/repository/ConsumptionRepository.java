package com.energy.backend.repository;

import com.energy.backend.model.Consumption;
import com.energy.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ConsumptionRepository extends JpaRepository<Consumption, Long> {
    List<Consumption> findByUser(User user);
    List<Consumption> findByUserAndType(User user, String type);

}

package com.energy.backend.controller;

import com.energy.backend.model.Consumption;
import com.energy.backend.model.User;
import com.energy.backend.repository.ConsumptionRepository;
import com.energy.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/consumptions")
public class ConsumptionController {

    @Autowired
    private ConsumptionRepository consumptionRepository;

    @Autowired
    private UserRepository userRepository;

    //Ajout manuel d'une consommation
    @PostMapping("/add")
    public ResponseEntity<?> addConsumption(
            @RequestBody Consumption consumption,
            Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(401).body("Utilisateur non authentifié");
        }

        String email = authentication.getName();

        User user = userRepository.findByEmail(email);

        if (user == null) {
            return ResponseEntity.status(404).body("Utilisateur introuvable");
        }

        consumption.setUser(user);

        Consumption saved = consumptionRepository.save(consumption);

        return ResponseEntity.ok(saved);
    }

    //Consommation de l'utilisateur connecté
    @GetMapping("/my")
    public ResponseEntity<?> getMyConsumptions(
            @RequestParam(required = false) String type,
            Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(401).body("Utilisateur non authentifié");
        }

        String email = authentication.getName();

        User user = userRepository.findByEmail(email);

        if (user == null) {
            return ResponseEntity.status(404).body("Utilisateur introuvable");
        }

        List<Consumption> consumptions;

        if (type != null && !type.equalsIgnoreCase("Tous")) {
            consumptions = consumptionRepository.findByUserAndType(user, type);
        } else {
            consumptions = consumptionRepository.findByUser(user);
        }

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON_UTF8)
                .body(consumptions);
    }

    //Import de CSV
    @PostMapping("/upload")
    public ResponseEntity<?> uploadCsv(
            @RequestParam("file") MultipartFile file,
            Authentication authentication) {

        try {

            //utilisateur connecté
            if (authentication == null) {
                return ResponseEntity.status(401).body("Utilisateur non authentifié");
            }

            String email = authentication.getName();

            User user = userRepository.findByEmail(email);

            if (user == null) {
                return ResponseEntity.status(404).body("Utilisateur introuvable");
            }

            //Pas fichier vide
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body("Fichier vide");
            }

            //extension CSV
            if (!file.getOriginalFilename().toLowerCase().endsWith(".csv")) {
                return ResponseEntity.badRequest().body("Seuls les fichiers CSV sont autorisés");
            }

            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(file.getInputStream(), java.nio.charset.StandardCharsets.UTF_8));

            String line;
            boolean firstLine = true;

            while ((line = reader.readLine()) != null) {

                // ignorer l'entête
                if (firstLine) {
                    firstLine = false;
                    continue;
                }

                String[] data = line.split(",");

                //3 colonnes
                if (data.length != 3) {
                    continue;
                }

                String dateStr = data[0].trim();
                String type = data[1].trim();
                String valueStr = data[2].trim();

                //Protection contre injection CSV
                if (type.startsWith("=") || type.startsWith("+") ||
                        type.startsWith("-") || type.startsWith("@")) {
                    continue;
                }

                // parse des données
                LocalDate date;
                double value;

                try {
                    date = LocalDate.parse(dateStr);
                    value = Double.parseDouble(valueStr);
                } catch (Exception e) {
                    continue;
                }

                Consumption consumption = new Consumption();
                consumption.setDate(date);
                consumption.setType(type);
                consumption.setValue(value);
                consumption.setUser(user);

                consumptionRepository.save(consumption);
            }

            return ResponseEntity.ok("Import CSV réussi");

        } catch (Exception e) {

            e.printStackTrace();

            return ResponseEntity
                    .status(500)
                    .body("Erreur import : " + e.getMessage());
        }
    }



}

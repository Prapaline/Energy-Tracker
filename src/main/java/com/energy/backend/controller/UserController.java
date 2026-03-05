package com.energy.backend.controller;

import com.energy.backend.model.User;
import com.energy.backend.repository.UserRepository;
import com.energy.backend.security.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/users")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    //Inscription
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user) {

        if (userRepository.findByEmail(user.getEmail()) != null) {
            return ResponseEntity
                    .badRequest()
                    .body("Cette adresse email existe déjà.");
        }

        user.setPassword(passwordEncoder.encode(user.getPassword()));

        User savedUser = userRepository.save(user);
        savedUser.setPassword(null);

        return ResponseEntity.ok(savedUser);
    }
    //Connexion
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User loginRequest) {

        User user = userRepository.findByEmail(loginRequest.getEmail());

        if (user == null ||
                !passwordEncoder.matches(loginRequest.getPassword(), user.getPassword())) {

            return ResponseEntity.badRequest()
                    .body("Email ou mot de passe incorrect.");
        }

        String token = jwtService.generateToken(user.getEmail());

        return ResponseEntity.ok().body(
                java.util.Map.of("token", token)
        );
    }


    //Récupération de l'utilisateur connecté
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(401).body("Utilisateur non authentifié");
        }

        String email = authentication.getName();
        User user = userRepository.findByEmail(email);

        if (user == null) {
            return ResponseEntity.status(404).body("Utilisateur introuvable");
        }

        user.setPassword(null);

        return ResponseEntity.ok(user);
    }
}

package com.rihla.transportservice.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableMethodSecurity
public class WebSecurityConfig {

    @Bean
    public AuthTokenFilter authTokenFilter(JwtUtils jwtUtils) {
        return new AuthTokenFilter(jwtUtils);
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, AuthTokenFilter authTokenFilter) throws Exception {
        http.csrf(csrf -> csrf.disable())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth

                        .requestMatchers(HttpMethod.GET, "/api/transports/trips/**").permitAll()
                        .requestMatchers(HttpMethod.PUT, "/api/transports/trips/*/reduce-seats").hasAnyRole("USER","ADMIN")

                        .requestMatchers(HttpMethod.POST, "/api/transports/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PUT, "/api/transports/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/transports/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PUT, "/api/transports/internal/**").permitAll()

                        .anyRequest().authenticated()
                );

        http.addFilterBefore(authTokenFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
//devsecops :
//gravana
//scan depenc and code
//

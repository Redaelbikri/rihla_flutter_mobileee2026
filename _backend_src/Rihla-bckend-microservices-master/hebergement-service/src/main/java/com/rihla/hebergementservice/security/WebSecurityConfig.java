package com.rihla.hebergementservice.security;

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


                        .requestMatchers(HttpMethod.GET, "/api/hebergements/**").permitAll()

                        .requestMatchers(HttpMethod.PUT, "/api/hebergements/*/reduce-stock").hasAnyRole("USER","ADMIN")

                        .requestMatchers(HttpMethod.POST, "/api/hebergements/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PUT, "/api/hebergements/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/hebergements/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PUT, "/api/hebergements/internal/**").permitAll()


                        .anyRequest().authenticated()
                );

        http.addFilterBefore(authTokenFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}

package com.eerp.api.auth;

public interface AuthService {
    LoginResponse login(LoginRequest request);

    void logout();
}
